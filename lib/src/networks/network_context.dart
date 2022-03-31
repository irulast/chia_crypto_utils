// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';

class NetworkContext {
  static Context makeContext(Network network) {
    final configurationProvider = ConfigurationProvider()
      ..setConfig(NetworkFactory.configId, {
        'yaml_file_path': 'lib/src/networks/chia/${network.name}/config.yaml'
      });
    final context = Context(configurationProvider);
    final blockchainNetworkLoader = ChiaBlockchainNetworkLoader();
    context.registerFactory(NetworkFactory(blockchainNetworkLoader.loadfromLocalFileSystem));
    return context;
  }
}

enum Network {
  mainnet,
  testnet10,
  testnet0,
}
