// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/context/network_context.dart';
import 'package:chia_crypto_utils/src/core/models/blockchain_network_loader.dart';
import 'package:chia_crypto_utils/src/networks/chia/chia_blockchain_network_loader.dart';

class ChiaNetworkContextWrapper extends NetworkContext {
  void registerNetworkContext(
    Network network, [
    Environment environment = Environment.pureDart,
  ]) {
    final chiaBlockchainNetworkLoader = ChiaBlockchainNetworkLoader();

    BlockchainNetworkLoaderFunction loader;
    switch (environment) {
      case Environment.pureDart:
        loader = chiaBlockchainNetworkLoader.loadfromLocalFileSystem;
        break;
      case Environment.flutter:
        loader = chiaBlockchainNetworkLoader.loadfromApplicationLib;
    }

    setPath('lib/src/networks/chia/${network.name}/config.yaml');
    setLoader(loader);
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
