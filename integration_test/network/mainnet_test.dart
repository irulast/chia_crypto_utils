// ignore_for_file: lines_longer_than_80_chars
@Skip('Test provided for reference, not nominally run')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';

import 'package:test/test.dart';

Future<void> main() async {
  final fullNodeUtils = FullNodeUtils(Network.mainnet);
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
  test('should get coins ', () async {
    final coins = await fullNode.getCoinsByPuzzleHashes(
      [
        Puzzlehash.fromHex(
          '51de5b7230cd32f245d5b577550294e070754ae1d9214e80c46f55c0ca914635',
        )
      ],
    );
    expect(coins.length == 3, true);
  });

  test('should get coins with specified start and end height', () async {
    final coins = await fullNode.getCoinsByPuzzleHashes(
      [
        Puzzlehash.fromHex(
          'a7850a501d90821b517d0c921c1c480f45a3369c08ae8236e2618a7fc97be14f',
        )
      ],
      startHeight: 1690666,
      endHeight: 1691337,
    );
    expect(coins.length == 2, true);
  });
}
