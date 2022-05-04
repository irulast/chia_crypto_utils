// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/src/context/network_context.dart';
import 'package:chia_utils/src/core/models/blockchain_network_loader.dart';
import 'package:chia_utils/src/networks/chia/chia_blockchain_network_loader.dart';

class ChiaNetworkContextWrapper extends NetworkContext {
  void registerNetworkContext(Network network, [Environment environment = Environment.pureDart]) {
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

enum Environment { pureDart, flutter }
