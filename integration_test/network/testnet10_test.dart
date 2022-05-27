// ignore_for_file: lines_longer_than_80_chars
@Skip('Test provided for reference, not nominally run')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';

import 'package:test/test.dart';

Future<void> main() async {
  final fullNodeUtils = FullNodeUtils(Network.testnet10);
  try {
    await fullNodeUtils.checkIsRunning();
  } catch (e) {
    print(e);
    return;
  }

  final fullNodeRpc = FullNodeHttpRpc(
    fullNodeUtils.url,
    certBytes: fullNodeUtils.certBytes,
    keyBytes: fullNodeUtils.keyBytes,
  );

  final fullNode = ChiaFullNodeInterface(fullNodeRpc);

  test('should get coins', () async {
    final coins = await fullNode.getCoinsByPuzzleHashes([
      Puzzlehash.fromHex(
        '0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad',
      )
    ]);
    expect(coins.length == 2, true);
  });
}
