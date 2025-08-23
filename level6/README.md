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