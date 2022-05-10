// ignore_for_file: lines_longer_than_80_chars, avoid_equals_and_hash_code_on_mutable_classes

import 'package:bip39/bip39.dart' as bip39;
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/curry_and_treehash/curry_and_treehash.clvm.hex.dart';
import 'package:chia_utils/src/utils/serialization.dart';

class WalletKeychain {
  Map<Puzzlehash, WalletVector> hardenedMap = <Puzzlehash, WalletVector>{};
  Map<Puzzlehash, UnhardenedWalletVector> unhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};
  static const mnemonicWordSeperator = ' ';

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    final walletVector = unhardenedMap[puzzlehash];

    if (walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash];
  }

  WalletKeychain(List<WalletSet> walletSets) {
    final newHardenedMap = <Puzzlehash, WalletVector>{};
    final newUnhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};

    for (final walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash] = walletSet.unhardened;
    }
    hardenedMap = newHardenedMap;
    unhardenedMap = newUnhardenedMap;
  }

  WalletKeychain.fromMaps(this.hardenedMap, this.unhardenedMap);

  factory WalletKeychain.fromBytes(Bytes bytes) {
    var byteIndex = 0;

    final hardenedMapLength = decodeInt(bytes.sublist(byteIndex, byteIndex + 4));
    byteIndex += 4;

    final hardenedMap = <Puzzlehash, WalletVector>{};

    for (var _i = 0; _i < hardenedMapLength; _i++) {
      final keyLength = decodeInt(bytes.sublist(byteIndex, byteIndex + 4));
      final keyLeft = byteIndex + 4;
      final keyRight = keyLeft + keyLength;

      final valueLength = decodeInt(bytes.sublist(keyRight, keyRight + 4));
      final valueLeft = keyRight + 4;
      final valueRight = valueLeft + valueLength;

      final puzzlehash = Puzzlehash(bytes.sublist(keyLeft, keyRight));
      final walletVector = WalletVector.fromBytes(bytes.sublist(valueLeft, valueRight));

      hardenedMap[puzzlehash] = walletVector;

      byteIndex = valueRight;
    }

    final unhardenedMapLength = decodeInt(bytes.sublist(byteIndex, byteIndex + 4));
    byteIndex += 4;

    final unhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};

    for (var _i = 0; _i < unhardenedMapLength; _i++) {
      final keyLength = decodeInt(bytes.sublist(byteIndex, byteIndex + 4));
      final keyLeft = byteIndex + 4;
      final keyRight = keyLeft + keyLength;

      final valueLength = decodeInt(bytes.sublist(keyRight, keyRight + 4));
      final valueLeft = keyRight + 4;
      final valueRight = valueLeft + valueLength;

      final puzzlehash = Puzzlehash(bytes.sublist(keyLeft, keyRight));
      final walletVector = UnhardenedWalletVector.fromBytes(bytes.sublist(valueLeft, valueRight));

      unhardenedMap[puzzlehash] = walletVector;

      byteIndex = valueRight;
    }

    return WalletKeychain.fromMaps(hardenedMap, unhardenedMap);
  }

  Bytes toBytes() {
    return serializeList(<dynamic>[hardenedMap, unhardenedMap]);
  }

  List<Puzzlehash> get puzzlehashes => unhardenedMap.values.toList().map((wv) => wv.puzzlehash).toList();

  List<Puzzlehash> getOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    if (!unhardenedMap.values.first.assetIdtoOuterPuzzlehash.containsKey(assetId)) {
      throw ArgumentError(
        'Puzzlehashes for given Asset Id are not in keychain',
      );
    }
    return unhardenedMap.values.map((v) => v.assetIdtoOuterPuzzlehash[assetId]!).toList();
  }

  void addOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    final entriesToAdd = <Puzzlehash, UnhardenedWalletVector>{};
    for (final walletVector in unhardenedMap.values) {
      final outerPuzzleHash = makeOuterPuzzleHash(walletVector.puzzlehash, assetId);
      walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
      entriesToAdd[outerPuzzleHash] = walletVector;
    }
    unhardenedMap.addAll(entriesToAdd);
  }

  static Puzzlehash makeOuterPuzzleHash(
    Puzzlehash innerPuzzleHash,
    Puzzlehash assetId,
  ) {
    final solution = Program.list([
      Program.fromBytes(catProgram.hash()),
      Program.fromBytes(assetId),
      Program.fromBytes(innerPuzzleHash)
    ]);
    final result = curryAndTreehashProgram.run(solution);
    return Puzzlehash(result.program.atom);
  }

  static List<String> generateMnemonic({int strength = 256}) {
    return bip39.generateMnemonic(strength: strength).split(mnemonicWordSeperator);
  }
}
