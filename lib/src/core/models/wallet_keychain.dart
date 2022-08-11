// ignore_for_file: lines_longer_than_80_chars, avoid_equals_and_hash_code_on_mutable_classes, prefer_collection_literals

import 'dart:collection';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class WalletKeychain with ToBytesMixin {
  WalletKeychain({
    required this.hardenedMap,
    required this.unhardenedMap,
    required this.singletonWalletVectorsMap,
  });

  factory WalletKeychain.fromWalletSets(List<WalletSet> walletSets) {
    final newHardenedMap = LinkedHashMap<Puzzlehash, WalletVector>();
    final newUnhardenedMap = LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();

    for (final walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash] = walletSet.unhardened;
    }

    return WalletKeychain(
      hardenedMap: newHardenedMap,
      unhardenedMap: newUnhardenedMap,
      singletonWalletVectorsMap: {},
    );
  }

  factory WalletKeychain.fromCoreSecret(
    KeychainCoreSecret coreSecret, {
    int walletSize = 5,
    int plotNftWalletSize = 2,
  }) {
    final masterPrivateKey = coreSecret.masterPrivateKey;
    final walletVectors = LinkedHashMap<Puzzlehash, WalletVector>();
    final unhardenedWalletVectors = LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();
    for (var i = 0; i < walletSize; i++) {
      final walletVector = WalletVector.fromPrivateKey(masterPrivateKey, i);
      final unhardenedWalletVector = UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);

      walletVectors[walletVector.puzzlehash] = walletVector;
      unhardenedWalletVectors[unhardenedWalletVector.puzzlehash] = unhardenedWalletVector;
    }

    final singletonVectors = <JacobianPoint, SingletonWalletVector>{};
    for (var i = 0; i < plotNftWalletSize; i++) {
      final singletonWalletVector = SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
      singletonVectors[singletonWalletVector.singletonOwnerPublicKey] = singletonWalletVector;
    }

    return WalletKeychain(
      hardenedMap: walletVectors,
      unhardenedMap: unhardenedWalletVectors,
      singletonWalletVectorsMap: singletonVectors,
    );
  }

  factory WalletKeychain.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final hardenedWalletVectorMap = LinkedHashMap<Puzzlehash, WalletVector>();
    final unhardenedWalletVectorMap = LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();
    final singletonWalletVectorMap = LinkedHashMap<JacobianPoint, SingletonWalletVector>();

    final nHardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nHardenedWalletVectors; _++) {
      final wv = WalletVector.fromStream(iterator);
      hardenedWalletVectorMap[wv.puzzlehash] = wv;
    }

    final nUnhardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nUnhardenedWalletVectors; _++) {
      final wv = UnhardenedWalletVector.fromStream(iterator);
      unhardenedWalletVectorMap[wv.puzzlehash] = wv;
      for (final outerPuzzlehash in wv.assetIdtoOuterPuzzlehash.values) {
        unhardenedWalletVectorMap[outerPuzzlehash] = wv;
      }
    }

    final nSingletonWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nSingletonWalletVectors; _++) {
      final wv = SingletonWalletVector.fromStream(iterator);
      singletonWalletVectorMap[wv.singletonOwnerPublicKey] = wv;
    }

    return WalletKeychain(
      hardenedMap: hardenedWalletVectorMap,
      unhardenedMap: unhardenedWalletVectorMap,
      singletonWalletVectorsMap: singletonWalletVectorMap,
    );
  }
  factory WalletKeychain.fromHex(String hex) => WalletKeychain.fromBytes(Bytes.fromHex(hex));

  @override
  Bytes toBytes() {
    return serializeListChia(hardenedWalletVectors) +
        serializeListChia(unhardenedWalletVectors) +
        serializeListChia(singletonWalletVectors);
  }

  final LinkedHashMap<Puzzlehash, WalletVector> hardenedMap;
  final LinkedHashMap<Puzzlehash, UnhardenedWalletVector> unhardenedMap;

  List<WalletVector> get hardenedWalletVectors => hardenedMap.values.toList();
  List<UnhardenedWalletVector> get unhardenedWalletVectors => unhardenedMap.values.toList();

  final Map<JacobianPoint, SingletonWalletVector> singletonWalletVectorsMap;

  List<SingletonWalletVector> get singletonWalletVectors =>
      singletonWalletVectorsMap.values.toList();

  SingletonWalletVector getNextSingletonWalletVector(PrivateKey masterPrivateKey) {
    final usedDerivationIndices = singletonWalletVectors.map((wv) => wv.derivationIndex).toList();

    var newDerivationIndex = 0;
    while (usedDerivationIndices.contains(newDerivationIndex)) {
      newDerivationIndex++;
    }

    final newSingletonWalletVector =
        SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, newDerivationIndex);

    singletonWalletVectorsMap[newSingletonWalletVector.singletonOwnerPublicKey] =
        newSingletonWalletVector;

    return newSingletonWalletVector;
  }

  SingletonWalletVector addSingletonWalletVectorForSingletonOwnerPublicKey(
    JacobianPoint singletonOwnerPublicKey,
    PrivateKey masterPrivateKey,
  ) {
    const maxIndexToCheck = 1000;
    for (var i = 0; i < maxIndexToCheck; i++) {
      final singletonOwnerSecretKey = masterSkToSingletonOwnerSk(masterPrivateKey, i);
      if (singletonOwnerSecretKey.getG1() == singletonOwnerPublicKey) {
        final newSingletonWalletVector =
            SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
        singletonWalletVectorsMap[singletonOwnerPublicKey] = newSingletonWalletVector;
        return newSingletonWalletVector;
      }
    }
    throw ArgumentError(
      'Given singletonOwnerPublicKey does not match mnemonic up to derivation index $maxIndexToCheck',
    );
  }

  SingletonWalletVector? getSingletonWalletVector(JacobianPoint ownerPublicKey) {
    return singletonWalletVectorsMap[ownerPublicKey];
  }

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    final walletVector = unhardenedMap[puzzlehash];

    if (walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash];
  }

  List<Puzzlehash> get puzzlehashes =>
      unhardenedMap.values.map((wv) => wv.puzzlehash).toSet().toList();
  List<Puzzlehash> getOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    if (!unhardenedMap.values.first.assetIdtoOuterPuzzlehash.containsKey(assetId)) {
      throw ArgumentError(
        'Puzzlehashes for given Asset Id are not in keychain',
      );
    }
    return unhardenedMap.values.map((v) => v.assetIdtoOuterPuzzlehash[assetId]!).toList();
  }

  HardenedAndUnhardenedPuzzleHashes addPuzzleHashes(
    PrivateKey masterPrivateKey,
    int numberOfPuzzleHashes,
  ) {
    final currentDerivationIndex = puzzlehashes.length;
    final unhardenedPuzzlehashes = <Puzzlehash>[];
    final hardenedPuzzlehashes = <Puzzlehash>[];
    for (var i = currentDerivationIndex; i < currentDerivationIndex + numberOfPuzzleHashes; i++) {
      final walletVector = WalletVector.fromPrivateKey(masterPrivateKey, i);
      final unhardenedWalletVector = UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);

      hardenedPuzzlehashes.add(walletVector.puzzlehash);
      unhardenedPuzzlehashes.add(unhardenedWalletVector.puzzlehash);

      hardenedMap[walletVector.puzzlehash] = walletVector;
      unhardenedMap[unhardenedWalletVector.puzzlehash] = unhardenedWalletVector;
    }
    return HardenedAndUnhardenedPuzzleHashes(
      hardened: hardenedPuzzlehashes,
      unhardened: unhardenedPuzzlehashes,
    );
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
}

class HardenedAndUnhardenedPuzzleHashes {
  HardenedAndUnhardenedPuzzleHashes({
    required this.hardened,
    required this.unhardened,
  });

  final List<Puzzlehash> hardened;
  final List<Puzzlehash> unhardened;
}
