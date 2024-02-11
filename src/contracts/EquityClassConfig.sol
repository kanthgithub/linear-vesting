//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EquityStakingConstants.sol";
import "forge-std/console.sol";

/// @title EquityClassConfig
/// @author kanth
/// @notice This contract is used to manage the configuration of different equity classes.
contract EquityClassConfig is EquityStakingConstants, Ownable {

    /// @notice Information about each equity class
    struct EquityClassInfo {
        uint256 totalTokens; // Total number of tokens for this class
        uint256 tokensPerVestingPeriod; // Number of tokens to be vested per period
        uint256 vestingRateBasisPoints; // in basis points
        uint256 cliffPeriod; // in seconds
        uint256 totalVestingPeriods; // in numerical value
    }

    /// @notice Maps each designation to its corresponding EquityClassInfo
    mapping(Designation => EquityClassInfo) public equityClasses;

    constructor(address _ownerAddress) Ownable(_ownerAddress) {}

    event EquityClassInfoSet(
        EquityStakingConstants.Designation indexed designation,
        uint256 totalTokens,
        uint256 vestingRateBasisPoints,
        uint256 cliffPeriod,
        uint256 tokensPerVestingPeriod
    );

    /// @notice Sets the information for a specific equity class
    /// @dev This function can only be called by the owner of the contract
    /// @param designation The designation of the equity class
    /// @param totalTokens The total number of tokens for this equity class
    /// @param vestingRateBasisPoints The vesting rate for this equity class, in basis points
    /// @param cliffPeriod The cliff period for this equity class
    function setEquityClassInfo(Designation designation, uint256 totalTokens, uint256 vestingRateBasisPoints, uint256 cliffPeriod) external onlyOwner {
        require(uint8(designation) <= uint8(Designation.Others), "Invalid designation");
        require(totalTokens > 0, "Total tokens must be greater than 0");
        require(vestingRateBasisPoints >= MIN_VESTING_RATE && vestingRateBasisPoints <= MAX_VESTING_RATE, "Vesting rate must be within 100-10000 basis points");

        // Calculate tokensPerVestingPeriod based on totalTokens and vestingRateBasisPoints
        uint256 tokensPerVestingPeriod = (totalTokens * vestingRateBasisPoints) / MAX_VESTING_RATE;

        // Calculate totalVestingPeriods based on the vestingRateBasisPoints
        uint256 totalVestingPeriods = MAX_VESTING_RATE / vestingRateBasisPoints;

        // Set the equity class information with the calculated tokensPerVestingPeriod
        equityClasses[designation] = EquityClassInfo({
            totalTokens: totalTokens,
            tokensPerVestingPeriod: tokensPerVestingPeriod,
            vestingRateBasisPoints: vestingRateBasisPoints,
            cliffPeriod: cliffPeriod,
            totalVestingPeriods: totalVestingPeriods
        });

        emit EquityClassInfoSet(designation, totalTokens, vestingRateBasisPoints, cliffPeriod, tokensPerVestingPeriod);
    }

}
