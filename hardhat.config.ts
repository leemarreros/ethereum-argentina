import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";
import "@openzeppelin/hardhat-upgrades";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  defender: {
    apiKey: process.env.API_KEY_DEFENDER,
    apiSecret: process.env.SECRET_KEY_DEFENDER,
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_TESNET_URL,
      accounts: [process.env.PRIVATE_KEY || ""],
      timeout: 20000,
      gas: "auto",
      gasPrice: "auto",
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.API_KEY_ETHERSCAN
    }
  }
};

export default config;
