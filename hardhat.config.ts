const path = require('path');
const fs = require("fs");
const env_path = path.join(__dirname, '.', '.env');
require('dotenv').config({
  path: fs.existsSync(env_path) ? env_path : path.join(__dirname, '.', '.local.env')
});

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-deploy";
import "hardhat-deploy-ethers";

const privateKeys = [
  process.env.ADMIN_KEY,
  /* accounts below for test */
  ...(process.env.ACCOUNTS === undefined ? []:process.env.ACCOUNTS.split(","))
].filter(a => !!a);

// default path (i.e.  `m/44'/60'/0'/0/0`
const mnemonic = process.env.MNEMONIC;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
    console.log((await hre.ethers.provider.getBalance(account.address)).toString());
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config = {
  mocha: {
    timeout: false
  },
  solidity: {
    compilers: [{
      version: "0.8.19",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }]
  },
  defaultNetwork: "hardhat",
  namedAccounts: {
    admin: 0
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
  networks: {
    hardhat: {
      saveDeployments: true,
      accounts: mnemonic !== undefined ?
        { mnemonic: mnemonic }
        : privateKeys.map((privateKey) => {
          return {privateKey: privateKey, balance: "1000000000000000000000000"}
        }),
      allowUnlimitedContractSize: true
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s3.binance.org:8545",
      accounts: privateKeys,
      chainId: 97,
      gasPrice: 10000000000,
      blockGasLimit: 30000000,
      allowUnlimitedContractSize: true,
      timeout: 120000
    },
    binance: {
      url: "https://bsc-dataseed.binance.org",
      accounts: privateKeys,
      chainId: 56,
      gasPrice: "auto",
      blockGasLimit: 79196578,
      allowUnlimitedContractSize: true,
      timeout: 120000
    },
  },
  paths: {
    sources: "contracts",
    tests: "tests",
    cache: "cache",
    artifacts: "artifacts",
    deploy: 'deploy',
    deployments: 'deployments',
    imports: 'imports'
  }
};

export default config;
