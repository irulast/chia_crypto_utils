// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];
  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 1; i++) {
    final set = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set);
  }
  final keychain = WalletKeychain(walletsSetList)
   ..addOuterPuzzleHashesForAssetId(Puzzlehash.fromHex('6357ddad396737e86e7e7efeb637d674d3cffb89080b028873aafab0f008590f'))
   ..addOuterPuzzleHashesForAssetId(Puzzlehash.fromHex('ba4484b961b7a2369d948d06c55b64bdbfaffb326bc13b490ab1215dd33d8d46'));

  final hardenedWalletVector = keychain.hardenedMap.values.first;
  final unhardenedWalletVector = keychain.unhardenedMap.values.first;

  test('should correctly serialize and deserialize hardened wallet vector', () {
    final serializedWalletVector = hardenedWalletVector.toJson();
    final deserializedWalletVector = WalletVector.fromJson(serializedWalletVector);

    expect(deserializedWalletVector, equals(hardenedWalletVector));
  });

  test('should correctly serialize and deserialize unhardened wallet vector', () {
    final serializedWalletVector = unhardenedWalletVector.toJson();
    final deserializedWalletVector = UnhardenedWalletVector.fromJson(serializedWalletVector);

    expect(deserializedWalletVector, equals(unhardenedWalletVector));
  });

}
