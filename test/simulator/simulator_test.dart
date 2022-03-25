import 'dart:convert';
import 'dart:io';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';
import 'package:path/path.dart' as path;

import 'blockchain_await_util.dart';
import '../../lib/src/api/simulator_http_rpc.dart';
import 'simulator_interface.dart';

Future<void> main() async {
  final simulator = SimulatorInterface();
  await simulator.farmCoins();
  // await simulator.farmCoins();
  // await simulator.farmCoins();
  // await simulator.farmCoins();
  await simulator.mintCats();

  final catCoins = await simulator.getCatCoins();
  print(catCoins);
  final coins = await simulator.getCoins();
    coins.forEach((element) {
    print('-------');
    // print(element.toJson());
    // print('id hex: ${element.id.toHex()}');
    print('parent_info: ${element.parentCoinInfo.toUint8List()}');
    // print('parent coin info hex: ' + element.parentCoinInfo.toHex());
    print('puzzle_hash: ${element.puzzlehash.toUint8List()}');
    print('amount: ${element.amount}');
  });
}
