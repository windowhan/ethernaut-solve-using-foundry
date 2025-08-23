# 지문
아래의 컨트랙트 코드를 주의 깊게 살펴보세요.

이 레벨을 클리어하려면:

* 이 컨트랙트의 **소유권을 획득**해야 합니다.
* 그리고 **잔액을 0으로 줄여야** 합니다.

도움이 될 수 있는 것들:

* ABI와 상호작용할 때 **이더를 전송하는 방법**
* ABI 바깥에서 **이더를 전송하는 방법**
* **wei와 ether 단위 변환** (help() 명령어 참고)
* **폴백(fallback) 메서드**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```

# 풀이
`contribute`함수의 코드를 보면 현재 owner의 `contributions`양보다 커야 owner가 될 수 있음.

contract가 생성될 때 극초기의 owner의 contributions는 말도안되게 큼
contribute 함수를 보면 현재 owner의 contributions을 뛰어넘어야만 owner권한을 줌 

근데 같은 contract 내의 `receive` handler를 보면 생각보다 간단한 조건으로 owner가 될 수 있음 
1. contribute함수를 호출해서 소량의 Native Token을 입금
2. target contract로 소량의 Native Token을 입금하면 `require(msg.value > 0 && contributions[msg.sender] > 0);`의 조건을 만족시킬 수 있음 