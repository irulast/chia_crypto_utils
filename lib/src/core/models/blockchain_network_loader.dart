import 'package:chia_utils/src/core/models/blockchain_network.dart';

abstract class BlockchainNetworkLoader {
  BlockchainNetwork loadfromLocalFileSystem(String path);
  BlockchainNetwork loadfromApplicationLib(String path);
}
