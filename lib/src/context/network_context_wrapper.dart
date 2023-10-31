// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/networks/chia/mainnet/mainnet_blockchain_network.dart';
import 'package:chia_crypto_utils/src/networks/chia/testnet0/testnet0_blockchain_network.dart';
import 'package:chia_crypto_utils/src/networks/chia/testnet10/testnet10_blockchain_network.dart';

class ChiaNetworkContextWrapper extends NetworkContext {
  void registerNetworkContext(
    Network network, {
    Environment environment = Environment.flutter,
  }) {
    final chiaBlockchainNetworkLoader = ChiaBlockchainNetworkLoader();

    BlockchainNetworkLoaderFunction loader;
    switch (environment) {
      case Environment.pureDart:
        loader = chiaBlockchainNetworkLoader.loadfromLocalFileSystem;
        setPath('lib/src/networks/chia/${network.name}/config.yaml');
        setLoader(loader);
        break;
      case Environment.flutter:
        setBlockchainNetwork(blockchainNetworks[network]!);
    }
  }
}

enum Network {
  mainnet,
  testnet10,
  testnet0,
}

Network stringToNetwork(String networkString) {
  switch (networkString) {
    case 'mainnet':
      return Network.mainnet;
    case 'testnet10':
      return Network.testnet10;
    case 'testnet0':
      return Network.testnet0;
    default:
      throw ArgumentError('Invalid Network String');
  }
}

enum Environment { pureDart, flutter }

final blockchainNetworks = {
  Network.mainnet: mainnetBlockchainNetwork,
  Network.testnet10: testnet10BlockchainNetwork,
  Network.testnet0: testnet0BlockchainNetwork,
};
