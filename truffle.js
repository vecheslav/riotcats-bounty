const HDWalletProvider = require("truffle-hdwallet-provider");
const mnemonic = 'YOUR MNEMONIC';

module.exports = {
  networks: {
    testrpc: {
      host: "127.0.0.1",
      port: 8544,
      network_id: "*" // Match any network id
    },
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 15
    },
    rinkeby: {
      provider: new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/INFURA_KEY'),
      network_id: 4
    },
    kovan: {
      provider: new HDWalletProvider(mnemonic, 'https://kovan.infura.io/INFURA_KEY'),
      network_id: 42
    },
    live: {
      provider: new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/INFURA_KEY'),
      network_id: 1
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    },
    outputSelection: {
      "*": {
        "*": [
          "abi"
        ]
      }
    }
  }
};
