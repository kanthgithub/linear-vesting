# Linear Vesting

Linear Vesting Contract offers the vesting arrangement for employees of various departments with in the organisation

Vesting is divided in to 3 categories:
1. CXO
2. SeniorManager
3. Others

More classes can be added based on requirement via EquityClassInfo

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

## Environment-Setup

- copy the `.env.example` file to `.env`

## Build

- Ensure you are on node version of 18.x.x or greater version
- Install the project dependencies 
```sh
yarn install
```

## Forge build

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

## Hardhat compilation

```sh
npx hardhat compile
```

## Testing

```sh
forge test
```
