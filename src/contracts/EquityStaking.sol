//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EquityStakingConstants.sol";
import "./EquityClassConfig.sol";

/// @title EquityStaking
/// @author Kanth
/// @notice This contract is used to manage the staking of equity tokens.
/// @dev All function calls are currently implemented without side effects
contract EquityStaking is EquityStakingConstants, Ownable {
    /// @notice The contract for managing equity class configurations    
    EquityClassConfig public immutable equityClassContract;
    
    /// @notice The contract for the equity token
    IERC20 public immutable equityTokenContract;

    /// @notice Information about each grant
    struct Grant {
        Designation designation;
        uint256 totalTokensForVesting;
        uint256 tokensPerVestingPeriod;
        uint256 totalVestingPeriods;
        uint256 claimedTokens;
        uint256 equityGrantedAt;
        uint256 cliffPeriod;
        uint256 vestingStartTime;
        uint256 vestingRateBasisPoints;
    }

    // Event emitted when equity is granted
    event EquityGranted(
        address indexed employee,
        uint256 totalTokens,
        uint256 vestingRateBasisPoints,
        uint256 cliffPeriod
    );

    // Event emitted when vested tokens are claimed
    event VestedTokensClaimed(
        address indexed employee,
        uint256 amount
    );

    mapping(address => Grant) public grants;

    /// @notice Constructs the EquityStaking contract
    /// @param _equityClassConfigAddress The address of the EquityClassConfig contract
    /// @param _equityTokenAddress The address of the equity token contract
    /// @param _ownerAddress The address of the owner of the contract
    constructor(address _equityClassConfigAddress, address _equityTokenAddress, address _ownerAddress) Ownable(_ownerAddress) {
        equityClassContract = EquityClassConfig(_equityClassConfigAddress);
        equityTokenContract = IERC20(_equityTokenAddress);
    }

    /// @notice Reverts any direct deposits to the contract
    /// @dev This function is called when someone sends Ether directly to the contract
    receive() external payable {
        revert("Direct deposits are not allowed");
    }

    /// @notice Grants equity to an employee
    /// @dev This function can only be called by the owner of the contract
    /// @param employee The address of the employee
    /// @param designation The designation of the employee
    function grantEquity(address employee, Designation designation) public onlyOwner {
        (uint256 totalTokens, uint256 tokensPerVestingPeriod, uint256 vestingRateBasisPoints, uint256 cliffPeriod, uint256 totalVestingPeriods) = equityClassContract.equityClasses(designation);
       
        grants[employee] = Grant({
            designation: designation,
            totalTokensForVesting: totalTokens,
            tokensPerVestingPeriod: tokensPerVestingPeriod,
            totalVestingPeriods: totalVestingPeriods,
            claimedTokens: 0,
            equityGrantedAt: block.timestamp,
            cliffPeriod: cliffPeriod,
            vestingStartTime: block.timestamp + cliffPeriod,
            vestingRateBasisPoints: vestingRateBasisPoints
        });

        emit EquityGranted(employee, totalTokens, vestingRateBasisPoints, cliffPeriod);
    }

    /// @notice Claims vested tokens for an employee
    /// @param employee The address of the employee
    function claimVestedTokens(address employee) external {
        require(msg.sender == employee || msg.sender == owner(), "Only the employee or owner can unlock vested tokens");

        Grant storage grant = grants[employee];
        require(block.timestamp > grant.vestingStartTime, "Cliff period not reached");

        uint256 vestedAmount = getVestedAmount(employee);

        require(vestedAmount > grant.claimedTokens, "No tokens to claim");

        uint256 tokensToClaim = vestedAmount - grant.claimedTokens;
        require(equityTokenContract.balanceOf(address(this)) >= tokensToClaim, "Not enough tokens in the contract");

        grant.claimedTokens = vestedAmount;

        bool transferSuccessful = equityTokenContract.transfer(employee, tokensToClaim);
        require(transferSuccessful, "Token transfer failed");

        emit VestedTokensClaimed(employee, vestedAmount);
    }

    /// @notice Returns the amount of tokens that an employee can currently claim
    /// @param employee The address of the employee
    /// @return The amount of tokens that the employee can currently claim
    function getClaimableAmount(address employee) public view returns (uint256) {
        uint256 vestedAmount = getVestedAmount(employee);
        Grant memory grant = grants[employee];
        if (vestedAmount < grant.claimedTokens) {
            return 0;
        }
        return vestedAmount - grant.claimedTokens;
    }

    /// @notice Generates a report of the vesting schedule for an employee
    /// @param employee The address of the employee
    /// @return totalTokensForVesting The total number of tokens for vesting
    /// @return tokensPerVestingPeriod The number of tokens to be vested per period
    /// @return totalVestingPeriods The total number of vesting periods
    /// @return claimedTokens The number of tokens already claimed
    /// @return vestedAmount The amount of tokens vested
    /// @return claimableAmount The amount of tokens that can be claimed
    function generateVestingReport(address employee) external view returns (
        uint256 totalTokensForVesting,
        uint256 tokensPerVestingPeriod,
        uint256 totalVestingPeriods,
        uint256 claimedTokens,
        uint256 vestedAmount,
        uint256 claimableAmount
    ) {
        Grant memory grant = grants[employee];
        vestedAmount = getVestedAmount(employee);
        claimableAmount = getClaimableAmount(employee);
        totalTokensForVesting = grant.totalTokensForVesting;
        tokensPerVestingPeriod = grant.tokensPerVestingPeriod;
        totalVestingPeriods = grant.totalVestingPeriods;
        claimedTokens = grant.claimedTokens;
    }

    /// @notice Returns the vested amount for a specific employee
    /// @param employee The address of the employee
    /// @return The vested amount for the employee
    function getVestedAmount(address employee) public view returns (uint256) {
        Grant memory grant = grants[employee];

        if (block.timestamp < grant.vestingStartTime) {
            return 0; // no tokens vested yet
        }

        // Calculate the total number of vesting intervals that have passed
        uint256 intervalsPassed = (block.timestamp - grant.vestingStartTime) / DURATION_PER_VESTING_PERIOD;

        // Ensure we don't calculate more than the total vesting periods
        uint256 effectiveIntervals = intervalsPassed > grant.totalVestingPeriods ? grant.totalVestingPeriods : intervalsPassed;

        // Calculate vested tokens
        return effectiveIntervals * grant.tokensPerVestingPeriod;
    }

    /// @notice Allows the owner to withdraw tokens in case of an emergency
    /// @dev This function can only be called by the owner of the contract
    function emergencyWithdraw(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        bool transferSuccessful = token.transfer(owner(), balance);
        require(transferSuccessful, "Token transfer failed");
    }
}
