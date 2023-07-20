require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "https://eth-sepolia";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0xkey";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "key";
const COINMARKET_API_KEY = process.env.COINMARKET_API_KEY || "key";

task(
  "accounts",
  "Prints the list of accounts and their balances",
  async (_, { ethers }) => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
      const balance = await account.getBalance();
      console.log("Account:", account.address);
      console.log("Balance:", ethers.utils.formatEther(balance), "ETH");
    }
  }
);

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
      blockConfirmations: 6,
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      //accounts: hardhat already placing them
      chainId: 31337,
    },
    ganache: {
      url: "http://127.0.0.1:8545/",
      accounts: [
        "68a3a98c86251867ffb483dd693d5a4d73f9806712c24674238c4e0d2a3d40ea",
      ],
      chainId: 1337,
    },
  },
  solidity: {
    compilers: [
      { version: "0.8.18" },
      { version: "0.6.6" },
      { version: "0.6.0" },
    ],
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: false,
    outputFile: "gas-report.txt",
    noColors: true,
    currency: "USD",
    coinmarketcap: COINMARKET_API_KEY,
    token: "MATIC",
  },
  namedAccounts: {
    deployer: {
      default: 0, //on default network will be the first account in the list
      //31337: 1, //on hardhat network will be the second(1) account in the list
    },
    user: {
      default: 1,
    },
  },
};
