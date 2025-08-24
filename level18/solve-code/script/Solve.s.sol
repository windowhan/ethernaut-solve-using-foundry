// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setSolver(address _solver) external;
    function solver() external view returns (address);
}

contract Recorder {
    address public sender;
    function whatIsTheMeaningOfLife() external returns (bytes32) {
        revert(string(abi.encodePacked("Hiiiii : ", msg.sender)));
        return bytes32(0);
    }
}
contract SolveScript is Script {
    address public target = 0xf3eE3C4Ec25e8414838567818A30C90c7d62f834;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        //Recorder helper = new Recorder();
        ITarget(target).setSolver(address(0x0e724267431C7131B53BE4F6E41310FDFE01c50f));
        Recorder r = Recorder(address(0x0e724267431C7131B53BE4F6E41310FDFE01c50f));
        bytes32 res = r.whatIsTheMeaningOfLife();

        console.logBytes32(res);
        console.log("solver : %s", ITarget(target).solver());
        vm.stopBroadcast();
    }
}
