# Kaiju Wallet

Kaiju Wallet is an ERC-4337 wallet designed to work seamlessly with games. Setup in one click and no need to remember or write down a recovery phrase.
Our Wallet keeps your funds and NFTs in a Smart Contract deployed on behalf of you. So you get access to the same wallet everywhere if you use the same login.Kaiju Wallet is beautifully crafted to bring the best experience to Web3 users with super sleek user interfaces. Our human centric design allows users to interact with people not with numbers.

## Kaiju Contracts
![contract_diagramme](https://github.com/kaijuweb3labs/kaiju-wallet-contract/assets/137517042/0cdd75ef-1d6c-4fa3-825b-73bac433644f)

## Kaiju Hardhat Project

This project contains all the contracts that has been used in the kaiju wallet.


### Deploy on network

1. Install dependencies
   ```shell
   yarn install
   ```
2. Compile the contracts
   ```shell
   yarn hardhat compile
   ```
3. Deploy the contracts.
   - deploy contracts to local node  `yarn hardhat-deploy --network localhost`
   - deploy contracts to polygon  `yarn hardhat-deploy --network polygon`
   - deploy contracts to polygon-mumbai  `yarn hardhat-deploy --network polygon-mumbai`
