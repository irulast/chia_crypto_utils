// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/core/models/blockchain_network.dart';

abstract class BlockchainNetworkLoader {
  BlockchainNetwork loadfromLocalFileSystem(String path);
  BlockchainNetwork loadfromApplicationLib(String path);
}

typedef BlockchainNetworkLoaderFunction = BlockchainNetwork Function(
  String path,
);
