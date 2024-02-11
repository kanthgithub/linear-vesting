pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/contracts/EquityClassConfig.sol";
import "../src/contracts/EquityStakingConstants.sol";
import "../src/contracts/EquityStaking.sol";
import "../src/contracts/ERC20Token.sol";
import "forge-std/console.sol";

contract EquityStakingTest is Test, EquityStakingConstants {
    address public owner;

    address public cxoAddress;
    address public seniorManagerAddress;
    address public developerAddress;

    EquityClassConfig public equityClassConfig;
    EquityStaking public equityStaking;
    ERC20Token public equityToken;
    uint256 public totalTokens;

    struct GrantInfoResponse {
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

    struct GrantRequest {
        uint256 totalTokens_CXO;
        uint256 vestingRateBasisPoints_CXO;
        uint256 totalTokens_SeniorManager;
        uint256 vestingRateBasisPoints_SeniorManager;
        uint256 totalTokens_Developer;
        uint256 vestingRateBasisPoints_Developer;
        uint256 cliffPeriod;
    }

    function setUp() public {
        owner = 0x246Add954192f59396785f7195b8CB36841a9bE8;
        cxoAddress = 0x9FC3da866e7DF3a1c57adE1a97c9f00a70f010c8;
        seniorManagerAddress = 0xBf94F0AC752C739F623C463b5210a7fb2cbb420B;
        developerAddress = 0x07C8f6e700FCf46cA307e1E09Ea14cD208222108;

        equityClassConfig = new EquityClassConfig(owner);
        equityToken = new ERC20Token("Equity Token", "EQTY", 18);
        equityStaking = new EquityStaking(
            address(equityClassConfig),
            address(equityToken),
            owner
        );
        totalTokens = 100000e18;
        //mint 1000 tokens to the owner
        equityToken.mint(address(equityStaking), 100000e18);

        //assert that the owner has 1000 tokens
        assertEq(equityToken.balanceOf(address(equityStaking)), 100000e18);
    }

    function testEquityStakingGrant() public {
        GrantRequest memory grantRequest;
        //set the equity class info
        grantRequest.totalTokens_CXO = 1000e18;
        grantRequest.vestingRateBasisPoints_CXO = 2500;
        grantRequest.totalTokens_SeniorManager = 800e18;
        grantRequest.vestingRateBasisPoints_SeniorManager = 2500;
        grantRequest.totalTokens_Developer = 400e18;
        grantRequest.vestingRateBasisPoints_Developer = 2000;
        grantRequest.cliffPeriod = 365 days;

        vm.startPrank(owner);
        equityClassConfig.setEquityClassInfo(
            EquityStakingConstants.Designation.CXO,
            grantRequest.totalTokens_CXO,
            grantRequest.vestingRateBasisPoints_CXO,
            grantRequest.cliffPeriod
        );
        equityClassConfig.setEquityClassInfo(
            EquityStakingConstants.Designation.SeniorManager,
            grantRequest.totalTokens_SeniorManager,
            grantRequest.vestingRateBasisPoints_SeniorManager,
            grantRequest.cliffPeriod
        );
        equityClassConfig.setEquityClassInfo(
            EquityStakingConstants.Designation.Others,
            grantRequest.totalTokens_Developer,
            grantRequest.vestingRateBasisPoints_Developer,
            grantRequest.cliffPeriod
        );

        //grant equity to the CXO
        equityStaking.grantEquity(
            cxoAddress,
            EquityStakingConstants.Designation.CXO
        );
        //grant equity to the SeniorManager
        equityStaking.grantEquity(
            seniorManagerAddress,
            EquityStakingConstants.Designation.SeniorManager
        );
        //grant equity to the Others
        equityStaking.grantEquity(
            developerAddress,
            EquityStakingConstants.Designation.Others
        );
        vm.stopPrank();

        GrantInfoResponse memory grantInfoResponse;

        //assert that the equity has been granted
        (
            grantInfoResponse.designation,
            grantInfoResponse.totalTokensForVesting,
            grantInfoResponse.tokensPerVestingPeriod,
            grantInfoResponse.totalVestingPeriods,
            grantInfoResponse.claimedTokens,
            ,
            grantInfoResponse.cliffPeriod,
            grantInfoResponse.vestingStartTime,
            grantInfoResponse.vestingRateBasisPoints
        ) = equityStaking.grants(cxoAddress);

        assertEq(
            uint8(grantInfoResponse.designation),
            uint8(EquityStakingConstants.Designation.CXO)
        );
        assertEq(
            grantInfoResponse.totalTokensForVesting,
            grantRequest.totalTokens_CXO
        );
        assertEq(
            grantInfoResponse.tokensPerVestingPeriod,
            grantRequest.totalTokens_CXO / 4
        );
        assertEq(grantInfoResponse.totalVestingPeriods, 4);
        assertEq(grantInfoResponse.claimedTokens, 0);
        assertEq(grantInfoResponse.cliffPeriod, grantRequest.cliffPeriod);
        assertEq(
            grantInfoResponse.vestingRateBasisPoints,
            grantRequest.vestingRateBasisPoints_CXO
        );

        //assert that the equity has been granted
        (
            grantInfoResponse.designation,
            grantInfoResponse.totalTokensForVesting,
            grantInfoResponse.tokensPerVestingPeriod,
            grantInfoResponse.totalVestingPeriods,
            grantInfoResponse.claimedTokens,
            ,
            grantInfoResponse.cliffPeriod,
            ,
            grantInfoResponse.vestingRateBasisPoints
        ) = equityStaking.grants(seniorManagerAddress);

        assertEq(
            uint8(grantInfoResponse.designation),
            uint8(EquityStakingConstants.Designation.SeniorManager)
        );
        assertEq(
            grantInfoResponse.totalTokensForVesting,
            grantRequest.totalTokens_SeniorManager
        );
        assertEq(
            grantInfoResponse.tokensPerVestingPeriod,
            grantRequest.totalTokens_SeniorManager / 4
        );
        assertEq(grantInfoResponse.totalVestingPeriods, 4);
        assertEq(grantInfoResponse.claimedTokens, 0);
        assertEq(grantInfoResponse.cliffPeriod, grantRequest.cliffPeriod);
        assertEq(
            grantInfoResponse.vestingRateBasisPoints,
            grantRequest.vestingRateBasisPoints_SeniorManager
        );

        (
            grantInfoResponse.designation,
            grantInfoResponse.totalTokensForVesting,
            grantInfoResponse.tokensPerVestingPeriod,
            grantInfoResponse.totalVestingPeriods,
            grantInfoResponse.claimedTokens,
            ,
            grantInfoResponse.cliffPeriod,
            ,
            grantInfoResponse.vestingRateBasisPoints
        ) = equityStaking.grants(developerAddress);

        assertEq(
            uint8(grantInfoResponse.designation),
            uint8(EquityStakingConstants.Designation.Others)
        );
        assertEq(
            grantInfoResponse.totalTokensForVesting,
            grantRequest.totalTokens_Developer
        );
        assertEq(
            grantInfoResponse.tokensPerVestingPeriod,
            grantRequest.totalTokens_Developer / 5
        );
        assertEq(grantInfoResponse.totalVestingPeriods, 5);
        assertEq(grantInfoResponse.claimedTokens, 0);
        assertEq(grantInfoResponse.cliffPeriod, grantRequest.cliffPeriod);
        assertEq(
            grantInfoResponse.vestingRateBasisPoints,
            grantRequest.vestingRateBasisPoints_Developer
        );

        // Simulate passing of time, e.g., warp 1 year into the future
        // Get the current block timestamp
        uint256 startTime = block.timestamp;
        uint256 timeToWarp = 365 * 2 days;
        vm.warp(startTime + timeToWarp);

        // Now, `block.timestamp` should be 1 day ahead of `startTime`
        assertEq(
            block.timestamp,
            startTime + timeToWarp,
            "Time warp did not work as expected"
        );

        uint256 vestedAmount = equityStaking.getVestedAmount(cxoAddress);
        assertEq(vestedAmount, 250e18);

        //claim the vested tokens
        uint256 claimableAmount = equityStaking.getClaimableAmount(cxoAddress);
        assertEq(claimableAmount, grantRequest.totalTokens_CXO / 4);

        uint256 balanceBefore = equityToken.balanceOf(cxoAddress);

        vm.startPrank(cxoAddress);
        equityStaking.claimVestedTokens(cxoAddress);
        vm.stopPrank();

        assertEq(
            equityToken.balanceOf(cxoAddress),
            claimableAmount,
            "Claimed tokens not equal to claimable amount"
        );

        // assert for change in token balance of cxoAddress
        uint256 balanceAfter = equityToken.balanceOf(cxoAddress);

        assertEq(
            balanceAfter,
            balanceBefore + claimableAmount,
            "Claimed tokens not added to the balance"
        );
    }
}
