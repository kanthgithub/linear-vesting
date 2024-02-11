import * as dotenv from 'dotenv'
import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
import { resolve } from "path";
import fs from "fs";

dotenv.config()

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => line.trim().split("="));
}

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000,
          },
          outputSelection: {
            "*": {
              "*": ["storageLayout"],
            },
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
      mumbai: process.env.POLYGONSCAN_API_KEY || "",
    },
  },
  networks: {
    mumbai: {
      url: process.env.POLYGON_MUMBAI_RPC ? process.env.POLYGON_MUMBAI_RPC : `https://rpc.ankr.com/polygon_mumbai`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    ec2: {
      url: 'http://ec2-13-233-156-135.ap-south-1.compute.amazonaws.com:8545',
      accounts: ["ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"],
    },
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5", // Make sure this is set to "ethers-v5"
  },
  paths: {
    sources: "./src/contracts/", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
}

export default config
