// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/clvm/bytes.dart';

class MixedAssetIdsException implements Exception {
  MixedAssetIdsException(this.mixedAssetIds);
  Iterable<Puzzlehash> mixedAssetIds;

  @override
  String toString() {
    return 'Can not mix cat coins with different asset ids for this operation: [${mixedAssetIds.map((tail) => tail.toHex())}]';
  }
}
