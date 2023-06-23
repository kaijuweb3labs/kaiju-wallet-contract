import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

import "hardhat-deploy";
import "@nomiclabs/hardhat-etherscan";

import "solidity-coverage";
import * as fs from "fs";

const optimizedComilerSettings = {
  version: "0.8.17",
  settings: {
    optimizer: { enabled: true, runs: 1000000 },
    viaIR: true,
  },
};


const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: { enabled: true, runs: 1000000 },
        },
      },
    ],
    overrides: {
      "@account-abstraction/contracts/core/EntryPoint.sol":
        optimizedComilerSettings,
      "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol":
        optimizedComilerSettings,
    },
  },
  networks: {
    polygon:{
      url:`https://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY!],
    } ,
    "polygon-mumbai":{
      url:`https://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY!],
    } ,
    hardhat: {
      initialBaseFeePerGas: 0,
      blockGasLimit: 1000000000,
      gas: 1000000000,
      gasPrice: 1000000000,
      gasMultiplier: 2,
      accounts: {
        mnemonic: "test ".repeat(11) + "junk",

      },
    },
  },
  mocha: {
    timeout: 10000,
  },
};

export default config;
