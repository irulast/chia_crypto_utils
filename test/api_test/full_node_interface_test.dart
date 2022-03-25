import 'dart:io';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/api/exceptions/bad_coin_id_exception.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import '../cat/cat_test_utils.dart';

Future<void> main() async {
  final simulatorHttpRpc = SimulatorHttpRpc('https://localhost:5000',
    certBytes: Bytes(File(path.join(path.current, 'test/simulator/temp/config/ssl/full_node/private_full_node.crt')).readAsBytesSync()),
    keyBytes: Bytes(File(path.join(path.current, 'test/simulator/temp/config/ssl/full_node/private_full_node.key')).readAsBytesSync()),
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  const testAddress = Address('xch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jkstxap9z');

  await fullNodeSimulator.farmCoins(testAddress);
  await fullNodeSimulator.moveToNextBlock();

  final nathanCoinMintSpendBundle = CatTestUtils.makeNateCoinSpendbundle();

  await fullNodeSimulator.pushTransaction(nathanCoinMintSpendBundle);
  await fullNodeSimulator.moveToNextBlock();

  
  final testStandardCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('27ae41e4649b934ca495991b7852b85500000000000000000000000000000001'), 
      puzzlehash: Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad'), 
      amount: 250000000000,
    ),
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('26081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0'), 
      puzzlehash: Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad'), 
      amount: 1749999990000,
    ),
  ];

  final testCatCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('0fe40b1ec35f3472c8cf0f244c207c26e7a8678413dceb87cff38dc2c1c95093'), 
      puzzlehash: Puzzlehash.fromHex('5db372b6e7577013035b4ee3fced2a7466d6ff1d3716b182afe520d83ee3427a'), 
      amount: 10000,
    ),
  ];
  

  test('should get standard coins by puzzlehashes', () async {
    final coins = await fullNodeSimulator.getCoinsByPuzzleHashes(testStandardCoins.map((c) => c.puzzlehash,).toList());
    for(final testCoin in testStandardCoins) {
      expect(coins.contains(testCoin), true);
    }
  });
  
  test('should get standard coin by id', () async {
    final coin = await fullNodeSimulator.getCoinById(testStandardCoins[0].id);
    expect(coin, testStandardCoins[0]);
  });

  test('should return null when coin is not found', () async {
    final coin = await fullNodeSimulator.getCoinById(Puzzlehash.fromHex('cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'));
    expect(coin, null);
  });

  test('should throw error when full node rejects invalid id', () async {
    var errorThrown = false;
    try {
      await fullNodeSimulator.getCoinById(Puzzlehash.fromHex('1cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'));
    } on BadCoinIdException catch (e) {
      errorThrown = true;
    }
    expect(errorThrown, true);
  });

  test('should get cat coins by puzzlehashes', () async {
    final coins = await fullNodeSimulator.getCoinsByPuzzleHashes(testCatCoins.map((c) => c.puzzlehash,).toList());
    for(final testCoin in testCatCoins) {
      expect(coins.contains(testCoin), true);
    }
  });
}
