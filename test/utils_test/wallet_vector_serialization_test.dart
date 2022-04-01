// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';

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

  final walletVector = keychain.unhardenedMap.values.first;
  final publicKey = walletVector.childPublicKey;

  // serialized public key
  final publicKeyHex = publicKey.toHex();
  print(publicKeyHex);

  // deserialize public key
  final publicKeyDeserialized = JacobianPoint.fromBytesG1(Bytes.fromHex(publicKeyHex).toUint8List());
  print(publicKeyDeserialized.toHex());

  // serialize outer puzzle hashmap
  final outerPuzzleHashes = walletVector.assetIdtoOuterPuzzlehash;
  final serializedOuterPuzzleHashes = outerPuzzleHashes.map((assetId, outerPuzzleHash) => MapEntry(assetId.toHex(), outerPuzzleHash.toHex()));
  print(serializedOuterPuzzleHashes);

  // deserialize outer puzzle hashmap
  final outerPuzzleHashesDeserialized = serializedOuterPuzzleHashes.map((assetIdHex, outerPuzzleHashHex) => MapEntry(Puzzlehash.fromHex(assetIdHex), Puzzlehash.fromHex(outerPuzzleHashHex)));

}
