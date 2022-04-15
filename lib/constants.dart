// Constants sourced from: https://docs.rarible.org/contract-addresses
//polygon collection 0x9f546C5a90E7C878dF91622D6EB43D8fb1Ef4b1C

/// NFT Minting Constants
// Constants sourced from: https://docs.rarible.org/contract-addresses
enum BlockchainFlavor {
  ropsten,
  rinkeby,
  ethMainNet,
  polygonMainNet,
  mumbai,
  unknown,
}

extension BlockchainFlavorExtention on BlockchainFlavor {
  static BlockchainFlavor fromChainId(int chainId) {
    switch (chainId) {
      case 80001:
        return BlockchainFlavor.mumbai;
      case 137:
        return BlockchainFlavor.polygonMainNet;
      case 3:
        return BlockchainFlavor.ropsten;
      case 4:
        return BlockchainFlavor.rinkeby;
      case 1:
        return BlockchainFlavor.ethMainNet;
      default:
        return BlockchainFlavor.unknown;
    }
  }
}

// For users to view the NFT's like on rarible.com
Map<BlockchainFlavor, String> raribleDotComMap = {
  BlockchainFlavor.ropsten: 'https://ropsten.rarible.com',
  BlockchainFlavor.rinkeby: 'https://rinkeby.rarible.com',
  BlockchainFlavor.ethMainNet: 'https://rarible.com',
  BlockchainFlavor.polygonMainNet: 'https://rarible.com',
  BlockchainFlavor.mumbai: 'https://rinkeby.rarible.com',
};

// API's all start with the basePath which is mapped to the respective chain
Map<BlockchainFlavor, String> basePathMap = {
  BlockchainFlavor.ropsten: 'https://ethereum-api-dev.rarible.org/',
  BlockchainFlavor.rinkeby: 'https://ethereum-api-staging.rarible.org/',
  BlockchainFlavor.ethMainNet: 'https://ethereum-api.rarible.org/',
  BlockchainFlavor.polygonMainNet: 'https://polygon-api.rarible.org/',
  BlockchainFlavor.mumbai: 'https://polygon-api-staging.rarible.org/',
};

// The ERC721 contracts - as deployed on the respective chains
Map<BlockchainFlavor, String> assetContractErc721Map = {
  BlockchainFlavor.ropsten: '0xB0EA149212Eb707a1E5FC1D2d3fD318a8d94cf05',
  BlockchainFlavor.rinkeby: '0x6ede7f3c26975aad32a475e1021d8f6f39c89d82',
  BlockchainFlavor.ethMainNet: '0xF6793dA657495ffeFF9Ee6350824910Abc21356C',
  BlockchainFlavor.mumbai: '0x5A3Ed919C18137dcC67fBEA707d7E41F3E498BEF',
  //BlockchainFlavor.mumbai: '0x9f546C5a90E7C878dF91622D6EB43D8fb1Ef4b1C',
};

// The ERC1152 contracts - as deployed on the respective chains
Map<BlockchainFlavor, String> assetContractErc11521Map = {
  BlockchainFlavor.ropsten: '0x6a94aC200342AC823F909F142a65232E2f052183',
  BlockchainFlavor.rinkeby: '0x1AF7A7555263F275433c6Bb0b8FdCD231F89B1D7',
  BlockchainFlavor.ethMainNet: '0xB66a603f4cFe17e3D27B87a8BfCaD319856518B8',
};

// ChainIds - likely should leverage https://chainlist.org/
Map<BlockchainFlavor, int> chainIdMap = {
  BlockchainFlavor.mumbai: 80001,
  BlockchainFlavor.polygonMainNet: 137,
  BlockchainFlavor.ropsten: 3,
  BlockchainFlavor.rinkeby: 4,
  BlockchainFlavor.ethMainNet: 1,
};

Map<BlockchainFlavor, String> chainIdDescription = {
  BlockchainFlavor.mumbai: 'Mumbai Testnet',
  BlockchainFlavor.polygonMainNet: 'Polygon Mainnet',
  BlockchainFlavor.ropsten: 'Ropsten Testnet',
  BlockchainFlavor.rinkeby: 'Rinkeby Testnet',
  BlockchainFlavor.ethMainNet: 'Ethereum Mainnet',
};

Map<BlockchainFlavor, String> blockExplorerMap = {
  BlockchainFlavor.ropsten: 'https://ropsten.etherscan.io/address',
  BlockchainFlavor.rinkeby: 'https://rinkeby.etherscan.io/address',
  BlockchainFlavor.ethMainNet: 'https://etherscan.io/address',
  BlockchainFlavor.mumbai: 'https://mumbai.polygonscan.com/address',
  BlockchainFlavor.polygonMainNet: 'https://polygonscan.com/address',
};

Map<BlockchainFlavor, String> faucetMap = {
  BlockchainFlavor.mumbai: 'https://faucet.polygon.technology/',
  BlockchainFlavor.polygonMainNet: 'none',
  BlockchainFlavor.ropsten: 'https://faucet.ropsten.be/',
  BlockchainFlavor.rinkeby: 'https://faucet.rinkeby.io/',
  BlockchainFlavor.ethMainNet: 'none',
};

// "ETHEREUM" "POLYGON" "FLOW" "TEZOS" "SOLANA"
// Testnets are differentiated by the api base url (i.e. api-staging.rarible.com)
Map<BlockchainFlavor, String> multiChainBlockchainMap = {
  BlockchainFlavor.mumbai: 'POLYGON',
  BlockchainFlavor.polygonMainNet: 'POLYGON',
  BlockchainFlavor.ropsten: 'ETHEREUM',
  BlockchainFlavor.rinkeby: 'ETHEREUM',
  BlockchainFlavor.ethMainNet: 'ETHEREUM',
};
