// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:get_it/get_it.dart';

class NetworkContext {
  final getIt = GetIt.I;

  void setPath(BlockchainNetworkPath path) {
    getIt
      ..registerSingleton<BlockchainNetworkPath>(path)
      ..allowReassignment = true;
  }

  void setLoader(BlockchainNetworkLoaderFunction loader) {
    BlockchainNetwork blockchainNetworkFactory() =>
        loader(getIt.get<BlockchainNetworkPath>());
    getIt
      ..registerLazySingleton<BlockchainNetwork>(blockchainNetworkFactory)
      ..allowReassignment = true;
  }

  BlockchainNetwork get blockchainNetwork => getIt<BlockchainNetwork>();
}

typedef BlockchainNetworkPath = String;
