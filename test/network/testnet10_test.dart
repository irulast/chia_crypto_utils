import 'dart:io';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  // final homePath = path.absolute(Platform.environment['HOME']!);
  // print(homePath);
  // final fullNodeRpc  = FullNodeHttpRpc(
  //   'https://localhost:8555',
  //   certBytes: Bytes(File(path.join(homePath, '.chia/testnet10/config/ssl/full_node/private_full_node.crt')).readAsBytesSync()),
  //   keyBytes: Bytes(File(path.join(homePath, '.chia/testnet10/config/ssl/full_node/private_full_node.key')).readAsBytesSync())
  // );

  // final fullNode = ChiaFullNodeInterface(fullNodeRpc);

  // final coins = await fullNode.getCoinsByPuzzleHashes([Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad')]);
  // print(coins);
}