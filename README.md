# Linear Vesting

Linear Vesting Contract offers the vesting arrangement for employees of various departments with in the organisation

Vesting classes is divided in to 3 categories based on designation of employees:
1. CXO
2. SeniorManager
3. Others

More classes/designations can be added based on requirement via EquityClassInfo & EquityStakingConstants

## Smart Contracts:

1. EquityClassConfig.sol

[EquityClassConfig](./src/contracts/EquityClassConfig.sol)

Contract to manage the equity classes(add/update the equity classes)
EquityClassInfo is mapped per Designation of the employee
Designations are defined as constants in EquityStakingConstants.sol

[EquityStakingConstants](./src/contracts/EquityStakingConstants.sol#L8)


2. EquityStaking.sol

- Grant staking for an employee with a designation
- Claim Vested Tokens for an employee based on the equityClass config settings of the designation
- Able to query the VestedTokenAmount & ClaimableTokenAmount of an employee by employee account address

## Sample Data

```
1. CXO - 1000 tokens, released 25% each year after a cliff period of 1 year.
2. Senior manager - 800 tokens, released 25% each year after a cliff period of 1 year.
3. Others - 400 tokens, released 20% each year after a cliff period of 1 year.
```

## Procedure to add new designations

1. Add new entry to enum `Designation` in `EquityStakingConstants.sol`
[Designations](./src/contracts/EquityStakingConstants.sol#L8)

## Procedure to add new EquityClassInfo

- EquityClassInfo contains the 
   1. totalTokens - Total number of tokens for this class
   2. tokensPerVestingPeriod -  Number of tokens to be vested per period
   3. vestingRateBasisPoints - in basis points
   4. cliffPeriod - cliff period in seconds
   5. totalVestingPeriods - in numerical value

- Only Owner of the `EquityClassConfig` contract can set or update info
  [setEquityClassInfo](./src/contracts/EquityClassConfig.sol#L40)
  
## Procedure to grant equity to an employee

1.  `grantEquity` function of `EquityStaking.sol` is called by admin with arguments:
     - employeeAddress
     - designation



## Testing

- Forge Unit tests are added to cover the scenarios:
1. test `setEquityClassInfo` & event emission assertion
2. test `grantEquity` for employee(s)
3. test assert the vested amount after simulating time advance
4. test assert the claimable amount (unlocked amount)
5. test assert the token transfer and balance of employee after claim


## Environment-Setup

- copy the `.env.example` file to `.env`

### Build

- Ensure you are on node version of 18.x.x or greater version
- Install the project dependencies 
```sh
yarn install
```

### Forge build

```sh
forge install OpenZeppelin/openzeppelin-contracts
```

```sh
forge install transmissions11/solmate
```

```sh
forge install foundry-rs/forge-std
```

```sh
forge build
```

### Hardhat compilation

```sh
npx hardhat compile
```

### Testing

```sh
forge test
```

## Feature Enhancements (Good to have)

1. Employee can do partial claim of the vestedAmount or claimableAmount
2. Ability to add varying duration of vesting period
    - can chose vesting period as quarter, half year, monthly instead of year 
    - Once fixed it remains same for the entire vesting cycle of the employee
3. Ensure Staking contract has the sufficient token balance right at time of `grantEquity`


## Tech Debt

1. Make Vesting-Contract Upgradeable
2. Convert require to revert with Custom Error Codes (Similar to Sablier-V2 contracts)
3. Deployment Scripts
4. Tooling around grantEquity, claim and view functions for staking.
   - tooling can be made as an API to manage from an UserInterface
