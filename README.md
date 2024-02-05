# cpu-v2
Charged Particles Multiverse

## Deploy

Using [hardhat deploy](https://github.com/wighawag/hardhat-deploy) hardhat plugin.

`yarn hardhat deploy  --network NETWORK --tags CONTRACT_TAG`

## Test

`yarn hardhat test --network hardhat`


### TODO
- Move bridge onto lib.
- Bridge inside the charged particle account.
- Investigate permit for account approvals.
- Enumerable oz set lib for allowlisted function signatures..
- Settings contract hook map.
- Check if NFT has set up a setting contract.
- Allow listed functions check inside the setting.
- Research settings manager contracts.