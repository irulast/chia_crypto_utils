// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:get_it/get_it.dart';

class NetworkContext {
  final getIt = GetIt.I;
  static const pathInstanceName = 'NetworkContext.path';

  void setPath(String path) {
    getIt
      ..registerSingleton<String>(path, instanceName: pathInstanceName)
      ..allowReassignment = true;
  }

  void setLoader(BlockchainNetworkLoaderFunction loader) {
    BlockchainNetwork blockchainNetworkFactory() =>
        loader(getIt.get<String>(instanceName: pathInstanceName));
    getIt
      ..registerLazySingleton<BlockchainNetwork>(blockchainNetworkFactory)
      ..allowReassignment = true;
  }

  void setBlockchainNetwork(BlockchainNetwork blockChainNetwork) {
    getIt
      ..registerSingleton<BlockchainNetwork>(blockChainNetwork)
      ..allowReassignment = true;
  }

  BlockchainNetwork get blockchainNetwork => getIt<BlockchainNetwork>();
}
