// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface ILottery {
  function fund() external payable;
  function withdraw() external;
}

contract Lottery {

    uint256 public constant TICKET_SIZE = 1 ether;
    uint8 public constant MAX_UINT8 = type(uint8).max;

    error DirectTransfersNotAllowed();
    error NotAPlayer();
    error InvalidPoolSize(uint8 poolSizeInEth);
    error MustFundExactly1Ether();
    error CanFundOnlyOnce();
    error PoolIsFull();
    error EthTransferFailed(address receiver, uint256 amount);
    error InvalidWinner(uint8 winningIndex);

    /// @notice Emitted when a player funds the lottery
    /// @param player The address of the player
    event Funded(address indexed player);

    /// @notice Emitted when a player withdraws from the lottery
    /// @param player The address of the player
    event Withdrawn(address indexed player);

    /// @notice Emitted when a winner is determined
    /// @param winner The address of the winner
    event Winner(address indexed winner);

    /// @notice _poolSizeInEth represents multiples of Eth, it is a whole number within range of [2, 10].
    uint8 public immutable poolSizeInEth;

    // count of players
    uint8 public playerCount = 0;

    // mapping of player address to their index in the playerAtIndex array
    // index of player is used to chose the winner and also to identify if player has entered the lottery and withdrawn
    mapping(address => uint8) public playerIndices;

    // mapping of index to player address
    // index-mapping is used to chose the winner and also to remove the player from the lottery
    mapping(uint8 => address) public playerAtIndex;

    // mapping of player address to their active status
    mapping(address => bool) public isActivePlayer;

    /// @notice Constructs the Lottery contract with the given poolSizeInEth
    constructor(uint8 _poolSizeInEth) {
        if (_poolSizeInEth < 2 || _poolSizeInEth > 10) {
        revert InvalidPoolSize(_poolSizeInEth);
        }
        poolSizeInEth = _poolSizeInEth;
    }

    // fallback function that reverts
    // this is to avoid direct transfers to the contract which will result in messing up with lottery state
    fallback() external {
        revert DirectTransfersNotAllowed();
    }

    // receive function that reverts
    // this is to avoid direct transfers to the contract which will result in messing up with lottery state
    receive() external payable {
        revert DirectTransfersNotAllowed();
    }

    /// @notice Allows a player to participate in the lottery
    /// @dev Requires that the player is not already a player
    /// @dev Requires that the player sends exactly 1 Ether
    /// @dev Requires that the pool is not full
    /// @dev If the pool is full, the winner is picked
    /// @dev If the winner is resolved to zero address, transaction will revert
    function fund() external payable virtual {
        
        if(isActivePlayer[msg.sender] || playerIndices[msg.sender] == MAX_UINT8) {
            revert CanFundOnlyOnce();
        }

        if (msg.value != TICKET_SIZE) {
            revert MustFundExactly1Ether();
        }

        if(address(this).balance >= poolSizeInEth) {
            revert PoolIsFull();
        }

        isActivePlayer[msg.sender] = true;
        playerIndices[msg.sender] = playerCount;
        playerAtIndex[playerCount] = msg.sender;
        playerCount++;
        emit Funded(msg.sender);
        if (address(this).balance == poolSizeInEth) {
            pickWinner();
        }
    }

    /// @notice Allows a player to withdraw from the lottery
    /// @dev Requires that the player is a player
    function withdraw() external virtual {
        if(!isActivePlayer[msg.sender]) {
            revert NotAPlayer();
        }

        uint8 index = playerIndices[msg.sender];

        // If the withdrawing player is not the last one, swap their position with the last player
        // this swapping is done to avoid a scenario where player address is resolved to zero address in mid of active indices
        // A gap in mapping would cause issue while picking the winner where winning index may be resolved to zero address
        if (index != playerCount - 1) {
            address lastPlayer = playerAtIndex[playerCount - 1];
            playerAtIndex[index] = lastPlayer;
            playerIndices[lastPlayer] = index;
        }

        // Set the withdrawn player's index to 255 and delete their address
        // this is to identify player has participated and withdrawn
        // we must avoid players to rejoin after leaving the lottery
        // this check - if the player has already participated in lottery is performed in fund() function
        playerIndices[msg.sender] = MAX_UINT8;

        // Delete the player at tail end (last player)
        delete playerAtIndex[playerCount - 1];

        //erase player in active players mapping
        isActivePlayer[msg.sender] = false;

        //decrement player count
        playerCount--;

        emit Withdrawn(msg.sender);

         //refund the ticket price back to the player
        _sendEth(msg.sender, TICKET_SIZE);
    }

    /// @notice Picks a winner from the list of active players
    /// @dev check if the pool is full is done by caller, so we don't need to check it here
    /// @dev The winner is picked using a random number generated from block-difficulty and current timestamp
    /// @dev The winner receives the entire pool amount
    /// @dev if the winner is resolved to zero address, transaction will revert
    function pickWinner() internal {
        uint8 winningIndex = uint8(_random() % playerCount);
        address winner = playerAtIndex[winningIndex];
        if(winner == address(0)) {
            revert InvalidWinner(winningIndex);
        }
        emit Winner(winner);
        payable(winner).transfer(address(this).balance);
    }

    /// @notice Sends Ether to the receiver
    /// @dev This function is used to refund the ticket price back to the player
    /// @dev This function is used to send the winning amount to the winner
    /// @param receiver The address of the receiver
    /// @param amount The amount of Ether to send
    function _sendEth(address receiver, uint256 amount) private {
        (bool success,) = payable(receiver).call{value: amount}("");
        if (!success) revert EthTransferFailed(receiver, amount);
    }

    /// @notice Generates a random number based on block-difficulty and current timestamp
    /// @dev block.prevrando is used which is equivalent to block.difficulty
    /// @dev difficulty is used to make the random number generation more secure
    /// @return The random number.
    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));
    }
}
