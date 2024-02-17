// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface ILottery {
  function fund() external payable;

  function withdraw() external;
}

contract LotteryUint8_Exact {
    mapping(address => uint8) public playerIndices;
    mapping(uint8 => address) public playerAtIndex;
    mapping(address => bool) public isActivePlayer;

    uint8 public poolSize;
    uint8 public participantCount = 0;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor(uint8 _poolSize) {
        require(_poolSize >= 2 ether && _poolSize <= 10 ether, "Pool size must be between 2 and 10 Eth");
        poolSize = _poolSize;
        owner = msg.sender;
    }

    function fund() external payable {
        require(!isActivePlayer[msg.sender] && playerIndices[msg.sender] < 255, "You can only fund once in each round");
        require(msg.value == 1 ether, "You can only fund exactly 1 Eth");
        require(address(this).balance <= poolSize, "The pool is full");
        isActivePlayer[msg.sender] = true;
        playerIndices[msg.sender] = participantCount;
        playerAtIndex[participantCount] = msg.sender;
        participantCount++;
        if (address(this).balance == poolSize) {
            pickWinner();
        }
    }

    function withdraw() external {
        require(isActivePlayer[msg.sender], "You are not a player in this round");
        require(address(this).balance < poolSize, "The pool is full, you cannot withdraw");
        isActivePlayer[msg.sender] = false;
        delete playerAtIndex[playerIndices[msg.sender]];
        playerIndices[msg.sender] = 255;
        participantCount--;
        payable(msg.sender).transfer(1 ether);
    }

    function pickWinner() internal {
        require(address(this).balance == poolSize, "The pool is not full yet");
        //uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)));
        uint random = uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp))) % participantCount;
        payable(playerAtIndex[uint8(random)]).transfer(address(this).balance);
    }
}
