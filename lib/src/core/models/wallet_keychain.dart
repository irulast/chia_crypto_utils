// ignore_for_file: lines_longer_than_80_chars, avoid_equals_and_hash_code_on_mutable_classes

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class WalletKeychain with ToBytesMixin {
  final Map<Puzzlehash, WalletVector> hardenedMap;
  List<WalletVector> get hardenedWalletVectors => hardenedMap.values.toList();

  final Map<Puzzlehash, UnhardenedWalletVector> unhardenedMap;
  List<UnhardenedWalletVector> get unhardenedWalletVectors => unhardenedMap.values.toList();

  final Map<JacobianPoint, SingletonWalletVector> singletonWalletVectorsMap;

  List<SingletonWalletVector> get singletonWalletVectors =>
      singletonWalletVectorsMap.values.toList();

  SingletonWalletVector addNewSingletonWalletVector(PrivateKey masterPrivateKey) {
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
      JacobianPoint singletonOwnerPublicKey, PrivateKey masterPrivateKey) {
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
    throw ArgumentError('Given singletonOwnerPublicKey does not match mnemonic');
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

  const WalletKeychain({
    this.hardenedMap = const {},
    this.unhardenedMap = const {},
    this.singletonWalletVectorsMap = const {},
  });

  factory WalletKeychain.fromWalletSets(List<WalletSet> walletSets) {
    final newHardenedMap = <Puzzlehash, WalletVector>{};
    final newUnhardenedMap = <Puzzlehash, UnhardenedWalletVector>{};

    for (final walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash] = walletSet.unhardened;
    }

    return WalletKeychain(
      hardenedMap: newHardenedMap,
      unhardenedMap: newUnhardenedMap,
    );
  }

  factory WalletKeychain.fromCoreSecret(
    KeychainCoreSecret coreSecret,
    int nDerivations,
  ) {
    final walletsSetList = <WalletSet>[];
    for (var i = 0; i < nDerivations; i++) {
      final set = WalletSet.fromPrivateKey(coreSecret.masterPrivateKey, i);
      walletsSetList.add(set);
    }

    return WalletKeychain.fromWalletSets(walletsSetList);
  }

  factory WalletKeychain.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final hardenedWalletVectorMap = <Puzzlehash, WalletVector>{};
    final unhardenedWalletVectorMap = <Puzzlehash, UnhardenedWalletVector>{};
    final singletonWalletVectorMap = <JacobianPoint, SingletonWalletVector>{};

    final nHardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nHardenedWalletVectors; _++) {
      final wv = WalletVector.fromStream(iterator);
      hardenedWalletVectorMap[wv.puzzlehash] = wv;
    }

    final nUnhardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nUnhardenedWalletVectors; _++) {
      final wv = UnhardenedWalletVector.fromStream(iterator);
      unhardenedWalletVectorMap[wv.puzzlehash] = wv;
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

  @override
  Bytes toBytes() {
    return serializeListChia(hardenedWalletVectors) +
        serializeList(unhardenedWalletVectors) +
        serializeList(singletonWalletVectors);
  }

  List<Puzzlehash> get puzzlehashes =>
      unhardenedMap.values.toList().map((wv) => wv.puzzlehash).toList();

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
}
