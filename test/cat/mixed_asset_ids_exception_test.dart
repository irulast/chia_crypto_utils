import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form', () {
    final Iterable<Puzzlehash> mixedAssetIds = [
      TestData.standardCoin.puzzlehash,
      TestData.coinFromChiaCoinRecordJson.puzzlehash
    ];
    expect(
      MixedAssetIdsException(mixedAssetIds).toString(),
      'Can not mix cat coins with different asset ids for this operation: '
      '[${mixedAssetIds.map((tail) => tail.toHex())}]',
    );
  });
}
