require('dotenv').config()
import { HardhatUserConfig } from 'hardhat/config';
import '@typechain/hardhat';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';
import 'hardhat-abi-exporter';
import '@nomicfoundation/hardhat-ethers';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-chai-matchers'

const mnemonic = {
  testnet: `${process.env.TESTNET_MNEMONIC}`.replace(/_/g, ' '),
  mainnet: `${process.env.MAINNET_MNEMONIC}`.replace(/_/g, ' '),
};
const optimizerDisabled = process.env.OPTIMIZER_DISABLED

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: !optimizerDisabled,
            runs: 200
          }
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    protocolOwner: {
      default: 1,
    },
    user1: {
      default: 2,
    },
    user2: {
      default: 3,
    },
    user3: {
      default: 4,
    },
  },
  paths: {
      sources: './contracts',
      tests: './test',
      cache: './cache',
      artifacts: './build/contracts',
      deploy: './deploy',
      deployments: './deployments'
  },
  networks: {
    hardhat: {
      chainId: 80001,
      forking: {
        url: "https://polygon-mainnet.g.alchemy.com/v2/" + process.env.ALCHEMY_API_KEY,
        blockNumber: 49144510
      },
      accounts: {
        mnemonic: mnemonic.testnet,
        initialIndex: 0,
        count: 10,
      },
    },
    goerli: {
        url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_APIKEY}`,
        gasPrice: 'auto',
        accounts: {
            mnemonic: mnemonic.testnet,
            initialIndex: 0,
            count: 10,
        },
        chainId: 5
    },
    sepolia: {
        url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_SEPOLIA_API_KEY}`,
        gasPrice: 'auto',
        accounts: {
            mnemonic: mnemonic.testnet,
            initialIndex: 0,
            count: 10,
        },
        chainId: 11155111
    },
    mainnet: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
        gasPrice: 'auto',
        accounts: {
            mnemonic: mnemonic.mainnet,
            initialIndex: 0,
            count: 10,
        }
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.io/v2/${process.env.ALCHEMY_MUMBAI_API_KEY}`,
        gasPrice: 10e9,
        accounts: {
            mnemonic: mnemonic.testnet,
            initialIndex: 0,
            count: 10,
        },
        chainId: 80001
    },
    polygon: {
        url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_POLYGON_API_KEY}`,
        gasPrice: 150e9,
        accounts: {
            mnemonic: mnemonic.mainnet,
            count: 8,
        },
        chainId: 137
    },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY ?? '',
      goerli: process.env.ETHERSCAN_API_KEY ?? '',
      polygon: process.env.POLYGONSCAN_API_KEY ?? '',
      polygonMumbai: process.env.POLYGONSCAN_API_KEY ?? '',
    }
  },
  gasReporter: {
      currency: 'USD',
      gasPrice: 32,
      enabled: (process.env.REPORT_GAS) ? true : false
  },
  abiExporter: {
    path: './abis',
    runOnCompile: true,
    clear: true,
    flat: true,
    only: [
      'ChargedParticles',
      'SmartAccount',
      'BufficornZK',
      'SmartAccountController_Example1',
    ],
  },
};

export default config;
