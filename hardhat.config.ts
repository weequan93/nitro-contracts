import '@nomiclabs/hardhat-waffle'
import 'hardhat-deploy'
import '@nomiclabs/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
import '@typechain/hardhat'
import 'solidity-coverage'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'
import 'hardhat-ignore-warnings'
// import '@tovarishfin/hardhat-yul';
import dotenv from 'dotenv'

dotenv.config()

const TEST_PK = '03c9b93a2534f0b459aeb81726cc8bd6160a16ab869f22f304457cff00318c68' // 0x57f93d0dfa75206f61f2bcd41cb61c499d48fe17
const PARENT_PK = '3f924b934c41a048183b48835acdb533b1d07045a38394b006b238a3fc07ea89' // 0x94a6713cbf5f589ab51570d0b4cd219792421af2
const CHILD_PK = '9c8b3de45967a4bc12930ae85f624b672797a01aa17554b310441cae36764564' // 0x8f48163d1932dc2286cc7d1f260e09c6ed07a1e0
const SUBACCOUNTOWNER = '90486089f0c0019fbf29ab904e332850c1dc7d723330005f7e8abaced4ba979e' // 0x1ae74be701339fb985f6837bc54d62630c4933bb

const solidity = {
  compilers: [
    {
      version: '0.8.9',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
      },
    },
  ],
  overrides: {
    'src/rollup/RollupUserLogic.sol': {
      version: '0.8.9',
      settings: {
        optimizer: {
          enabled: true,
          runs: 0,
        },
      },
    },
    'src/mocks/HostioTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
    'src/mocks/ArbOS11To32UpgradeTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
  },
}

if (process.env['INTERFACE_TESTER_SOLC_VERSION']) {
  solidity.compilers.push({
    version: process.env['INTERFACE_TESTER_SOLC_VERSION'],
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  })
  solidity.overrides = {
    'src/test-helpers/InterfaceCompatibilityTester.sol': {
      version: process.env['INTERFACE_TESTER_SOLC_VERSION'],
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
      },
    },
    'src/mocks/HostioTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
    'src/mocks/ArbOS11To32UpgradeTest.sol': {
      version: '0.8.24',
      settings: {
        optimizer: {
          enabled: true,
          runs: 100,
        },
        evmVersion: 'cancun',
      },
    },
  }
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity,
  paths: {
    sources: './src',
    artifacts: 'build/contracts',
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks: {
    hardhat: {
      chainId: 1338,
      throwOnTransactionFailures: true,
      allowUnlimitedContractSize: true,
      accounts: {
        accountsBalance: '1000000000000000000000000000',
      },
      blockGasLimit: 200000000,
      // mining: {
      //   auto: false,
      //   interval: 1000,
      // },
      forking: {
        url: 'https://mainnet.infura.io/v3/' + process.env['INFURA_KEY'],
        enabled: process.env['SHOULD_FORK'] === '1',
      },
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    sepolia: {
      url: 'https://sepolia.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    holesky: {
      url: 'https://holesky.infura.io/v3/' + process.env['INFURA_KEY'],
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arbRinkeby: {
      url: 'https://rinkeby.arbitrum.io/rpc',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arbGoerliRollup: {
      url: 'https://goerli-rollup.arbitrum.io/rpc',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arbSepolia: {
      url: 'https://sepolia-rollup.arbitrum.io/rpc',
      timeout: 10000000,
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    arb1: {
      url: 'https://arb1.arbitrum.io/rpc',
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    nova: {
      url: 'https://nova.arbitrum.io/rpc',
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    base: {
      url: 'https://mainnet.base.org',
      accounts: process.env['MAINNET_PRIVKEY']
        ? [process.env['MAINNET_PRIVKEY']]
        : [],
    },
    baseSepolia: {
      url: 'https://sepolia.base.org',
      accounts: process.env['DEVNET_PRIVKEY']
        ? [process.env['DEVNET_PRIVKEY']]
        : [],
    },
    geth: {
      url: 'http://localhost:8545',
    },
    local: {
      chainId: 42691720113,
      url: 'http://127.0.0.1:8449',
      accounts: [TEST_PK, PARENT_PK, CHILD_PK, SUBACCOUNTOWNER],
    },
    devnet: {
      chainId: 2884,
      url: 'https://rpc.dev.deriw.com',
      accounts: [TEST_PK, PARENT_PK, CHILD_PK, SUBACCOUNTOWNER],
    },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env['ETHERSCAN_API_KEY'],
      goerli: process.env['ETHERSCAN_API_KEY'],
      sepolia: process.env['ETHERSCAN_API_KEY'],
      holesky: process.env['ETHERSCAN_API_KEY'],
      arbitrumOne: process.env['ARBISCAN_API_KEY'],
      arbitrumTestnet: process.env['ARBISCAN_API_KEY'],
      nova: process.env['NOVA_ARBISCAN_API_KEY'],
      arbGoerliRollup: process.env['ARBISCAN_API_KEY'],
      arbSepolia: process.env['ARBISCAN_API_KEY'],
      base: process.env['BASESCAN_API_KEY'],
      baseSepolia: process.env['BASESCAN_API_KEY'],
    },
    customChains: [
      {
        network: 'nova',
        chainId: 42170,
        urls: {
          apiURL: 'https://api-nova.arbiscan.io/api',
          browserURL: 'https://nova.arbiscan.io/',
        },
      },
      {
        network: 'arbGoerliRollup',
        chainId: 421613,
        urls: {
          apiURL: 'https://api-goerli.arbiscan.io/api',
          browserURL: 'https://goerli.arbiscan.io/',
        },
      },
      {
        network: 'arbSepolia',
        chainId: 421614,
        urls: {
          apiURL: 'https://api-sepolia.arbiscan.io/api',
          browserURL: 'https://sepolia.arbiscan.io/',
        },
      },
    ],
  },
  mocha: {
    timeout: 100000000,
  },
  gasReporter: {
    enabled: process.env.DISABLE_GAS_REPORTER ? false : true,
  },
  typechain: {
    outDir: 'build/types',
    target: 'ethers-v5',
  },
  contractSizer: {
    strict: true,
  },
}
