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
        
        console.log("Level 26: Double Entry Point");
        console.log("Target (DoubleEntryPoint):", target);

        // DoubleEntryPoint에서 필요한 주소들 가져오기
        IDoubleEntryPoint doubleEntryPoint = IDoubleEntryPoint(target);
        address cryptoVault = doubleEntryPoint.cryptoVault();
        address forta = doubleEntryPoint.forta();
        
        console.log("CryptoVault:", cryptoVault);
        console.log("Forta:", forta);

        // DetectionBot 배포
        DetectionBot detectionBot = new DetectionBot(cryptoVault, forta);
        console.log("DetectionBot deployed at:", address(detectionBot));
        
        // Forta에 DetectionBot 등록
        IForta(forta).setDetectionBot(address(detectionBot));
        console.log("DetectionBot registered to Forta");
        
        console.log("Solution completed!");
        console.log("The DetectionBot will now protect against the double entry point attack");
        console.log("by detecting when delegateTransfer is called with CryptoVault as origSender");

        vm.stopBroadcast();
    }
}
