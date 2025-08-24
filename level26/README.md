# 지문

이 레벨에는 `sweepToken`이라는 특별한 기능을 가진 **CryptoVault**가 등장합니다.
`sweepToken`은 컨트랙트에 잘못 전송된 토큰들을 회수하는 데 자주 사용되는 함수입니다.
CryptoVault는 \*\*기본 토큰(underlying token)\*\*을 보관하고 있는데, 이 기본 토큰은 CryptoVault의 핵심 로직에 해당하기 때문에 `sweepToken`으로는 회수할 수 없습니다. 다른 토큰들은 자유롭게 회수할 수 있습니다.

기본 토큰은 **DoubleEntryPoint** 컨트랙트에 구현된 **DET 토큰** 인스턴스이며, CryptoVault는 이 DET 토큰을 100개 보관하고 있습니다. 또한 CryptoVault는 **LegacyToken (LGT)** 100개도 가지고 있습니다.

이 레벨에서 당신은 **CryptoVault의 버그를 찾아내고, 토큰이 탈취당하지 않도록 보호하는 방법**을 알아내야 합니다.

컨트랙트에는 **Forta**라는 컨트랙트도 존재합니다. 이곳에서는 누구나 자신만의 \*\*탐지 봇(detection bot)\*\*을 등록할 수 있습니다.
Forta는 탈중앙화된 커뮤니티 기반 모니터링 네트워크로, DeFi, NFT, 거버넌스, 브리지 및 기타 Web3 시스템에서 발생하는 위협이나 이상 징후를 신속히 감지하는 역할을 합니다.

당신의 임무는 탐지 봇을 구현하고 이를 Forta 컨트랙트에 등록하는 것입니다.
봇은 올바른 상황에서 경고(alert)를 발생시켜 잠재적인 공격이나 버그 악용을 방지해야 합니다.

---

도움이 될 만한 것들:

* **토큰 컨트랙트에서 Double Entry Point는 어떻게 동작하는가?**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/access/Ownable.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

interface DelegateERC20 {
    function delegateTransfer(address to, uint256 value, address origSender) external returns (bool);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

contract Forta is IForta {
    mapping(address => IDetectionBot) public usersDetectionBots;
    mapping(address => uint256) public botRaisedAlerts;

    function setDetectionBot(address detectionBotAddress) external override {
        usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
    }

    function notify(address user, bytes calldata msgData) external override {
        if (address(usersDetectionBots[user]) == address(0)) return;
        try usersDetectionBots[user].handleTransaction(user, msgData) {
            return;
        } catch {}
    }

    function raiseAlert(address user) external override {
        if (address(usersDetectionBots[user]) != msg.sender) return;
        botRaisedAlerts[msg.sender] += 1;
    }
}

contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying;

    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
    }

    /*
    ...
    */

    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
    }
}

contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    DelegateERC20 public delegate;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}

contract DoubleEntryPoint is ERC20("DoubleEntryPointToken", "DET"), DelegateERC20, Ownable {
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    constructor(address legacyToken, address vaultAddress, address fortaAddress, address playerAddress) {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    modifier onlyDelegateFrom() {
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    modifier fortaNotify() {
        address detectionBot = address(forta.usersDetectionBots(player));

        // Cache old number of bot alerts
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // Notify Forta
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        if (forta.botRaisedAlerts(detectionBot) > previousValue) revert("Alert has been triggered, reverting");
    }

    function delegateTransfer(address to, uint256 value, address origSender)
        public
        override
        onlyDelegateFrom
        fortaNotify
        returns (bool)
    {
        _transfer(origSender, to, value);
        return true;
    }
}
```

# 풀이 

문제를 요약하면 DetectionBot을 구현한 뒤에 Forta Contract에 등록해서 자금이 유출되는것을 막아야함.

그렇기 위해서는 해당 문제에 존재하는 취약점이 무엇인지 찾아야됨.

모티브가 된 사건은 https://medium.com/chainsecurity/trueusd-compound-vulnerability-bc5b696d29e2 에 소개되어있음.


`LegacyToken`이 있고 `DoubleEntryPoint` contract가 있는데 문제는 `LegacyToken`의 `delegate`가 `DoubleEntryPoint`로 되어있음.
어차피 `LegacyToken`의 `transfer`함수는 어차피 `msg.sender`, 사용자의 balance에 기반해서 다른 사람의 자금을 손댈수없지않을까 싶지만 이것이 sweepToken 함수와 결합햇을 때 취약점이 됨.
`sweepToken`함수는 보통 유저들이 실수로 자금을 컨트랙트로 보냈을 때 구제해주려고 만들어놓은 기능임.

그래서 실제로 contract에서 쓰이는 토큰은 `sweepToken`으로 구출하지못하도록 되어있음.
문제는 그렇게 blacklist되어있는 Token주소가 `DoubleEntryPoint` contract뿐이라는거임.

`sweepToken` 함수의 파라미터로 `LegacyToken`을 넘긴다면 저 시점의 `LegacyToken`의 `transfer`함수 호출의 `msg.sender`는 `CryptoVault`가 되기때문에 자금 유출이 가능함

이점을 감안해서 감지봇을 짜는건 아래와 같이 작성하면됨.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

// 필요한 인터페이스들
interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

interface IDoubleEntryPoint {
    function cryptoVault() external view returns (address);
    function forta() external view returns (address);
}

// Detection Bot 구현
contract DetectionBot is IDetectionBot {
    address private cryptoVault;
    IForta private forta;

    constructor(address _cryptoVault, address _forta) {
        cryptoVault = _cryptoVault;
        forta = IForta(_forta);
    }

    function handleTransaction(address user, bytes calldata msgData) external override {
        // delegateTransfer 함수 selector
        bytes4 delegateTransferSelector = bytes4(keccak256("delegateTransfer(address,uint256,address)"));

        // msgData의 길이가 최소한 함수 시그니처 + 3개 파라미터 (4 + 32*3 = 100바이트) 있는지 확인
        if (msgData.length >= 100 && bytes4(msgData[:4]) == delegateTransferSelector) {
            // origSender는 3번째 파라미터 (오프셋: 4 + 32 + 32 = 68바이트)
            address origSender = abi.decode(msgData[68:100], (address));

            // origSender가 CryptoVault인 경우 alert 발생
            if (origSender == cryptoVault) {
                forta.raiseAlert(user);
            }
        }
    }
}

contract SolveScript is Script {
    address public target = 0xf9b42E09Fd787d6864D6b2Cd8E1350fc93E6683D;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        
        IDoubleEntryPoint doubleEntryPoint = IDoubleEntryPoint(target);
        address cryptoVault = doubleEntryPoint.cryptoVault();
        address forta = doubleEntryPoint.forta();
        
        console.log("CryptoVault: %s", cryptoVault);
        console.log("Forta: %s", forta);
        
        DetectionBot detectionBot = new DetectionBot(cryptoVault, forta);
        console.log("DetectionBot : %s", address(detectionBot));
        
        IForta(forta).setDetectionBot(address(detectionBot));
        vm.stopBroadcast();
    }
}
```
