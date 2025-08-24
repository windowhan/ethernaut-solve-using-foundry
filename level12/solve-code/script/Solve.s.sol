// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function unlock(bytes16 _key) external;
    function locked() external view returns (bool);
}
contract SolveScript is Script {
    address public target = 0x94099942864EA81cCF197E9D71ac53310b1468D8;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        bytes32 a = 0x5158f37949c453b9c2477b6cabbf6eefaff55b698dbb595cb054e8e306b72e99;
        console.logBool(ITarget(target).locked());
        ITarget(target).unlock(bytes16(a));
        console.logBool(ITarget(target).locked());
        vm.stopBroadcast();
    }
}
