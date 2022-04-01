// ignore_for_file: lines_longer_than_80_chars

import 'package:bip39/bip39.dart' as bip39;
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/curry_and_treehash/curry_and_treehash.clvm.hex.dart';

class WalletKeychain {
  Map<Puzzlehash, WalletVector> hardenedMap = <Puzzlehash, WalletVector>{};
  Map<Puzzlehash, UnhardenedWalletVector> unhardenedMap =
      <Puzzlehash, UnhardenedWalletVector>{};
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
  WalletKeychain._internal({
    required this.hardenedMap,
    required this.unhardenedMap,
  });

  List<Puzzlehash> getOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    if (!unhardenedMap.values.first.assetIdtoOuterPuzzlehash
        .containsKey(assetId)) {
      throw ArgumentError(
          'Puzzlehashes for given Asset Id are not in keychain');
    }
    return unhardenedMap.values
        .map((v) => v.assetIdtoOuterPuzzlehash[assetId]!)
        .toList();
  }

  void addOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    final entriesToAdd = <Puzzlehash, UnhardenedWalletVector>{};
    for (final walletVector in unhardenedMap.values) {
      final outerPuzzleHash =
          makeOuterPuzzleHash(walletVector.puzzlehash, assetId);
      walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
      entriesToAdd[outerPuzzleHash] = walletVector;
    }

    unhardenedMap.addAll(entriesToAdd);

    /**
     * Add the hardened puzzlehashes for the assetId
     */
    final hardenedEntriesToAdd = <Puzzlehash, WalletVector>{};
    for (final walletVector in hardenedMap.values) {
      final outerPuzzleHash =
          WalletKeychain.makeOuterPuzzleHash(walletVector.puzzlehash, assetId);
      //walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
      hardenedEntriesToAdd[outerPuzzleHash] = walletVector;
    }
    hardenedMap.addAll(hardenedEntriesToAdd);
  }

  static Puzzlehash makeOuterPuzzleHash(
      Puzzlehash innerPuzzleHash, Puzzlehash assetId) {
    final solution = Program.list([
      Program.fromBytes(catProgram.hash()),
      Program.fromBytes(assetId.toUint8List()),
      Program.fromBytes(innerPuzzleHash.toUint8List())
    ]);
    final result = curryAndTreehashProgram.run(solution);
    return Puzzlehash(result.program.atom);
  }

  static List<String> generateMnemonic({int strength = 256}) {
    return bip39
        .generateMnemonic(strength: strength)
        .split(mnemonicWordSeperator);
  }

  factory WalletKeychain.fromMap(Map<String, dynamic> json) {
    final hardened = json['hardenedMap'] as Map<String, dynamic>;
    final unhardened = json['unhardenedMap'] as Map<String, dynamic>;

    final hardenedMap = <Puzzlehash, WalletVector>{};
    final unhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};

    for (final key in hardened.keys) {
      final value = hardened[key] as Map<String, dynamic>;
      final puzzlehash = Puzzlehash.fromHex(key);
      final walletVector = WalletVector.fromMap(value);
      hardenedMap[puzzlehash] = walletVector;
    }
    for (final key in unhardened.keys) {
      final value = unhardened[key] as Map<String, dynamic>;
      final puzzlehash = Puzzlehash.fromHex(key);
      final unhardenedWalletVector = UnhardenedWalletVector.fromMap(value);
      unhardenedMap[puzzlehash] = unhardenedWalletVector;
    }

    return WalletKeychain._internal(
      hardenedMap: hardenedMap,
      unhardenedMap: unhardenedMap,
    );
  }
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['hardenedMap'] =
        hardenedMap.map((k, v) => MapEntry(k.toHex(), v.toMap()));
    map['unhardenedMap'] =
        unhardenedMap.map((k, v) => MapEntry(k.toHex(), v.toMap()));
    return map;
  }
}
