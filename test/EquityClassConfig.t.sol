pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/contracts/EquityClassConfig.sol";
import "../src/contracts/EquityStakingConstants.sol";

contract EquityClassConfigTest is Test {

    EquityClassConfig public equityClassConfig;
    address public owner;

    event EquityClassInfoSet(
        EquityStakingConstants.Designation indexed designation,
        uint256 totalTokens,
        uint256 vestingRateBasisPoints,
        uint256 cliffPeriod,
        uint256 tokensPerVestingPeriod
    );

    function setUp() public {
        owner = 0x246Add954192f59396785f7195b8CB36841a9bE8;
        equityClassConfig = new EquityClassConfig(owner);
    }

    function testSetEquityClassInfo() public {

       EquityStakingConstants.Designation designation = EquityStakingConstants.Designation.CXO;
       uint256 totalTokens = 1000e18;
       uint256 vestingRateBasisPoints = 2500;
       uint256 cliffPeriod = 365 days;

       uint256 tokensPerVestingPeriod_expected = 250e18;
       uint256 totalVestingPeriods_expected = 4;

       emit EquityClassInfoSet(
            designation,
            totalTokens,
            vestingRateBasisPoints,
            cliffPeriod,
            tokensPerVestingPeriod_expected
        );

        vm.startPrank(owner);
        equityClassConfig.setEquityClassInfo(EquityStakingConstants.Designation.CXO, 1000e18, 2500, 365 days);
        vm.stopPrank();

        (uint256 totalTokens_actual, uint256 tokensPerVestingPeriod_actual, uint256 vestingRateBasisPoints_actual, uint256 cliffPeriod_actual, uint256 totalVestingPeriods_actual) = equityClassConfig.equityClasses(EquityStakingConstants.Designation.CXO);

        assertEq(totalTokens_actual, totalTokens);
        assertEq(vestingRateBasisPoints_actual, vestingRateBasisPoints);
        assertEq(cliffPeriod_actual, cliffPeriod);
        assertEq(tokensPerVestingPeriod_actual, tokensPerVestingPeriod_expected);
        assertEq(totalVestingPeriods_actual, totalVestingPeriods_expected);
    }
}
