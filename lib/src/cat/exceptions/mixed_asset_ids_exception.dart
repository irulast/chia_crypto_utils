import 'package:chia_utils/src/core/models/puzzlehash.dart';

class MixedAssetIdsException implements Exception {
  Iterable<Puzzlehash> mixedAssetIds;

  MixedAssetIdsException(this.mixedAssetIds);

  @override
  String toString() {
    return 'Can not mix cat coins with different asset ids for this opperation: [${mixedAssetIds.map((tail) => tail.hex)}]';
  }
}
