//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract EquityStakingConstants {
    uint public constant MIN_VESTING_RATE = 100; // 1% as basis points
    uint public constant MAX_VESTING_RATE = 10000; // 100% as basis points
    uint256  public constant DURATION_PER_VESTING_PERIOD = 365 days;
    enum Designation { CXO, SeniorManager, Others }
}