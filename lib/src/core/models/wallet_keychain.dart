// ignore_for_file: lines_longer_than_80_chars, avoid_equals_and_hash_code_on_mutable_classes, prefer_collection_literals

import 'dart:collection';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/exceptions/keychain_mismatch_exception.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:deep_pick/deep_pick.dart';

class WalletKeychain with ToBytesMixin {
  WalletKeychain({
    required this.hardenedMap,
    required this.unhardenedMap,
    required this.singletonWalletVectorsMap,
  });
  factory WalletKeychain.fromCoreSecret(
    KeychainCoreSecret coreSecret, {
    int walletSize = 5,
    int plotNftWalletSize = 2,
    void Function(double progress)? onProgressUpdate,
  }) {
    final totalWalletVectorsToGenerate = (walletSize * 2) + plotNftWalletSize;
    var totalWalletVectorsGenerated = 0;

    void incrementAndCallUpdate() {
      totalWalletVectorsGenerated++;
      onProgressUpdate
          ?.call(totalWalletVectorsGenerated / totalWalletVectorsToGenerate);
    }

    final masterPrivateKey = coreSecret.masterPrivateKey;
    final walletVectors = LinkedHashMap<Puzzlehash, WalletVector>();
    final unhardenedWalletVectors =
        LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();
    for (var i = 0; i < walletSize; i++) {
      final walletVector =
          WalletVector.fromMasterPrivateKey(masterPrivateKey, i);
      incrementAndCallUpdate();

      final unhardenedWalletVector =
          UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);
      incrementAndCallUpdate();

      walletVectors[walletVector.puzzlehash] = walletVector;
      unhardenedWalletVectors[unhardenedWalletVector.puzzlehash] =
          unhardenedWalletVector;
    }

    final singletonVectors = <JacobianPoint, SingletonWalletVector>{};
    for (var i = 0; i < plotNftWalletSize; i++) {
      final singletonWalletVector =
          SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
      incrementAndCallUpdate();

      singletonVectors[singletonWalletVector.singletonOwnerPublicKey] =
          singletonWalletVector;
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
    final unhardenedWalletVectorMap =
        LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();
    final singletonWalletVectorMap =
        LinkedHashMap<JacobianPoint, SingletonWalletVector>();

    final nHardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nHardenedWalletVectors; _++) {
      final wv = WalletVector.fromStream(iterator, _);
      hardenedWalletVectorMap[wv.puzzlehash] = wv;
    }

    final nUnhardenedWalletVectors = intFrom32BitsStream(iterator);
    for (var _ = 0; _ < nUnhardenedWalletVectors; _++) {
      final wv = UnhardenedWalletVector.fromStream(iterator, _);
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
  factory WalletKeychain.fromHex(String hex) =>
      WalletKeychain.fromBytes(Bytes.fromHex(hex));

  factory WalletKeychain.fromWalletSets(List<WalletSet> walletSets) {
    final newHardenedMap = LinkedHashMap<Puzzlehash, WalletVector>();
    final newUnhardenedMap =
        LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();

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

  static Map<String, dynamic> _walletKeychainFromCoreSecretTask(
    WalletKeychainFromCoreSecretIsolateArguments arguments,
    void Function(double progress) onProgressUpdate,
  ) {
    final keychain = WalletKeychain.fromCoreSecret(
      arguments.coreSecret,
      walletSize: arguments.walletSize,
      plotNftWalletSize: arguments.plotNftWalletSize,
      onProgressUpdate: onProgressUpdate,
    );
    return <String, dynamic>{
      'keychain': keychain.toHex(),
    };
  }

  static Future<WalletKeychain> fromCoreSecretAsync(
    KeychainCoreSecret coreSecret, {
    int walletSize = 5,
    int plotNftWalletSize = 2,
    void Function(double progress)? onProgressUpdate,
  }) async {
    return spawnAndWaitForIsolateWithProgressUpdates(
      taskArgument: WalletKeychainFromCoreSecretIsolateArguments(
        coreSecret: coreSecret,
        walletSize: walletSize,
        plotNftWalletSize: plotNftWalletSize,
      ),
      onProgressUpdate: onProgressUpdate ?? (_) {},
      isolateTask: _walletKeychainFromCoreSecretTask,
      handleTaskCompletion: (taskResultJson) =>
          WalletKeychain.fromHex(taskResultJson['keychain'] as String),
    );
  }

  @override
  Bytes toBytes() {
    return serializeListChia(hardenedWalletVectors) +
        serializeListChia(unhardenedWalletVectors) +
        serializeListChia(singletonWalletVectors);
  }

  final LinkedHashMap<Puzzlehash, WalletVector> hardenedMap;
  final LinkedHashMap<Puzzlehash, UnhardenedWalletVector> unhardenedMap;

  List<WalletVector> get hardenedWalletVectors => hardenedMap.values.toList();
  List<UnhardenedWalletVector> get unhardenedWalletVectors {
    final seenUnhardenedWalletVectorPuzzlehashes = <Puzzlehash>{};
    final uniqueUnhardenedWalletVectors = unhardenedMap.values
        .where(
          (wv) => seenUnhardenedWalletVectorPuzzlehashes.add(wv.puzzlehash),
        )
        .toList();
    return uniqueUnhardenedWalletVectors;
  }

  final Map<JacobianPoint, SingletonWalletVector> singletonWalletVectorsMap;

  List<SingletonWalletVector> get singletonWalletVectors =>
      singletonWalletVectorsMap.values.toList();

  SingletonWalletVector getNextSingletonWalletVector(
    PrivateKey masterPrivateKey,
  ) {
    final usedDerivationIndices =
        singletonWalletVectors.map((wv) => wv.derivationIndex).toList();

    var newDerivationIndex = 0;
    while (usedDerivationIndices.contains(newDerivationIndex)) {
      newDerivationIndex++;
    }

    final newSingletonWalletVector = SingletonWalletVector.fromMasterPrivateKey(
      masterPrivateKey,
      newDerivationIndex,
    );

    singletonWalletVectorsMap[newSingletonWalletVector
        .singletonOwnerPublicKey] = newSingletonWalletVector;

    return newSingletonWalletVector;
  }

  Map<String, dynamic> _getSingletonWalletVectorForSingletonOwnerPublicKeyTask(
    AddsSingletonWalletVectorArguments args,
  ) {
    final masterPrivateKey = args.masterPrivateKey;
    final singletonOwnerPublicKey = args.singletonOwnerPublicKey;
    const maxIndexToCheck = 1000;
    for (var i = 0; i < maxIndexToCheck; i++) {
      final singletonOwnerSecretKey =
          masterSkToSingletonOwnerSk(masterPrivateKey, i);
      if (singletonOwnerSecretKey.getG1() == singletonOwnerPublicKey) {
        final newSingletonWalletVector =
            SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);

        return <String, dynamic>{
          'singleton_wallet_vector': newSingletonWalletVector.toHex(),
        };
      }
    }

    return <String, dynamic>{
      'singleton_wallet_vector': null,
    };
  }

  Future<SingletonWalletVector>
      addSingletonWalletVectorForSingletonOwnerPublicKeyAsync(
    JacobianPoint singletonOwnerPublicKey,
    PrivateKey masterPrivateKey,
  ) async {
    final newSingletonWalletVector = await spawnAndWaitForIsolate(
      taskArgument: AddsSingletonWalletVectorArguments(
        singletonOwnerPublicKey,
        masterPrivateKey,
      ),
      isolateTask: _getSingletonWalletVectorForSingletonOwnerPublicKeyTask,
      handleTaskCompletion: (taskResultJson) {
        final result = taskResultJson['singleton_wallet_vector'] as String?;
        if (result == null) {
          return null;
        }
        return SingletonWalletVector.fromHex(result);
      },
    );

    if (newSingletonWalletVector == null) {
      throw Exception(
        'Given singletonOwnerPublicKey does not match mnemonic up',
      );
    }

    singletonWalletVectorsMap[singletonOwnerPublicKey] =
        newSingletonWalletVector;
    return newSingletonWalletVector;
  }

  SingletonWalletVector addSingletonWalletVectorForSingletonOwnerPublicKey(
    JacobianPoint singletonOwnerPublicKey,
    PrivateKey masterPrivateKey,
  ) {
    const maxIndexToCheck = 1000;
    for (var i = 0; i < maxIndexToCheck; i++) {
      final singletonOwnerSecretKey =
          masterSkToSingletonOwnerSk(masterPrivateKey, i);
      if (singletonOwnerSecretKey.getG1() == singletonOwnerPublicKey) {
        final newSingletonWalletVector =
            SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
        singletonWalletVectorsMap[singletonOwnerPublicKey] =
            newSingletonWalletVector;
        return newSingletonWalletVector;
      }
    }
    throw Exception(
      'Given singletonOwnerPublicKey does not match mnemonic up to derivation index $maxIndexToCheck',
    );
  }

  SingletonWalletVector? getSingletonWalletVector(
    JacobianPoint ownerPublicKey,
  ) {
    return singletonWalletVectorsMap[ownerPublicKey];
  }

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    final walletVector = unhardenedMap[puzzlehash];

    if (walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash];
  }

  /// throws [KeychainMismatchException] if puzzlehash does not belong to keychain
  WalletVector getWalletVectorOrThrow(Puzzlehash puzzlehash) {
    final walletVector = getWalletVector(puzzlehash);
    if (walletVector == null) throw KeychainMismatchException(puzzlehash);
    return walletVector;
  }

  List<Puzzlehash> get puzzlehashes => LinkedHashSet<Puzzlehash>.from(
        unhardenedMap.values.map<Puzzlehash>((wv) => wv.puzzlehash),
      ).toList();

  List<Puzzlehash> get puzzlehashesHardened => LinkedHashSet<Puzzlehash>.from(
        hardenedMap.values.map<Puzzlehash>((wv) => wv.puzzlehash),
      ).toList();

  List<WalletPuzzlehash> get walletPuzzlehashes =>
      LinkedHashSet<WalletPuzzlehash>.from(
        unhardenedMap.values.map<WalletPuzzlehash>((wv) => wv.walletPuzzlehash),
      ).toList();

  List<WalletPuzzlehash> get walletPuzzlehashesHardened =>
      LinkedHashSet<WalletPuzzlehash>.from(
        hardenedMap.values.map<WalletPuzzlehash>((wv) => wv.walletPuzzlehash),
      ).toList();

  List<Puzzlehash> getOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    if (!hasAssetId(assetId)) {
      throw ArgumentError(
        'Puzzlehashes for given Asset Id are not in keychain',
      );
    }
    return unhardenedMap.values
        .map((v) => v.assetIdtoOuterPuzzlehash[assetId]!)
        .toList();
  }

  bool hasAssetId(Puzzlehash assetId) {
    return unhardenedMap.values.first.assetIdtoOuterPuzzlehash
        .containsKey(assetId);
  }

  MixedPuzzlehashes addPuzzleHashes(
    PrivateKey masterPrivateKey,
    int numberOfPuzzleHashes,
  ) {
    final currentDerivationIndex = puzzlehashes.length;
    final unhardenedPuzzlehashes = <WalletPuzzlehash>[];
    final hardenedPuzzlehashes = <WalletPuzzlehash>[];
    final outerPuzzlehashes = <Puzzlehash, Set<WalletPuzzlehash>>{};

    for (var i = currentDerivationIndex;
        i < currentDerivationIndex + numberOfPuzzleHashes;
        i++) {
      final walletVector =
          WalletVector.fromMasterPrivateKey(masterPrivateKey, i);
      final unhardenedWalletVector =
          UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);

      hardenedPuzzlehashes.add(walletVector.walletPuzzlehash);
      unhardenedPuzzlehashes.add(unhardenedWalletVector.walletPuzzlehash);

      for (final assetId
          in unhardenedWalletVectors.first.assetIdtoOuterPuzzlehash.keys) {
        final outerPuzzleHash =
            makeOuterPuzzleHash(walletVector.puzzlehash, assetId);

        unhardenedWalletVector.assetIdtoOuterPuzzlehash[assetId] =
            outerPuzzleHash;
        unhardenedMap[outerPuzzleHash] = unhardenedWalletVector;

        outerPuzzlehashes.update(
          assetId,
          (value) => {...value, WalletPuzzlehash(outerPuzzleHash, i)},
          ifAbsent: () => {WalletPuzzlehash(outerPuzzleHash, i)},
        );
      }

      hardenedMap[walletVector.puzzlehash] = walletVector;
      unhardenedMap[unhardenedWalletVector.puzzlehash] = unhardenedWalletVector;
    }
    return MixedPuzzlehashes(
      hardened: hardenedPuzzlehashes,
      unhardened: unhardenedPuzzlehashes,
      outer:
          outerPuzzlehashes.map((key, value) => MapEntry(key, value.toList())),
    );
  }

  Set<Puzzlehash> get assetIds =>
      unhardenedWalletVectors.first.assetIdtoOuterPuzzlehash.keys.toSet();

  List<WalletPuzzlehash> addOuterPuzzleHashesForAssetId(
    Puzzlehash assetId, {
    void Function(double progress)? onProgressUpdate,
  }) {
    return _addOuterPuzzleHashesForAssetId(
      assetId,
      cat2Program,
      onProgressUpdate: onProgressUpdate,
    );
  }

  List<WalletPuzzlehash> addCat1OuterPuzzleHashesForAssetId(
    Puzzlehash assetId, {
    void Function(double progress)? onProgressUpdate,
  }) {
    return _addOuterPuzzleHashesForAssetId(
      assetId,
      cat1Program,
      onProgressUpdate: onProgressUpdate,
    );
  }

  static Puzzlehash makeOuterPuzzleHash(
    Puzzlehash innerPuzzleHash,
    Puzzlehash assetId,
  ) {
    return makeOuterPuzzleHashForCatProgram(
      innerPuzzleHash,
      assetId,
      cat2Program,
    );
  }

  static Puzzlehash makeCat1OuterPuzzleHash(
    Puzzlehash innerPuzzleHash,
    Puzzlehash assetId,
  ) {
    return makeOuterPuzzleHashForCatProgram(
      innerPuzzleHash,
      assetId,
      cat1Program,
    );
  }

  List<WalletPuzzlehash> addOuterPuzzleHashesForInnerPuzzlehashes(
    List<Puzzlehash> innerPuzzlehashes,
    Puzzlehash assetId,
  ) {
    return addOuterPuzzleHashesForInnerPuzzleHashesGeneric(
      innerPuzzlehashes,
      assetId,
      cat2Program,
    );
  }

  List<WalletPuzzlehash> addCat1OuterPuzzleHashesForInnerPuzzlehashes(
    List<Puzzlehash> innerPuzzlehashes,
    Puzzlehash assetId,
  ) {
    return addOuterPuzzleHashesForInnerPuzzleHashesGeneric(
      innerPuzzlehashes,
      assetId,
      cat1Program,
    );
  }

  List<WalletPuzzlehash> addOuterPuzzleHashesForInnerPuzzleHashesGeneric(
    List<Puzzlehash> innerPuzzlehashes,
    Puzzlehash assetId,
    Program program,
  ) {
    final entriesToAdd = <Puzzlehash, UnhardenedWalletVector>{};

    final outerPuzzleHashes = <WalletPuzzlehash>{};

    for (final innerPuzzlehash in innerPuzzlehashes) {
      final walletVector = unhardenedMap[innerPuzzlehash];
      if (walletVector == null) {
        throw KeyMismatchException(
          'Inner puzzlehash $innerPuzzlehash does not belong to keychain',
        );
      }
      if (walletVector.assetIdtoOuterPuzzlehash.containsKey(assetId)) {
        continue;
      }
      final outerPuzzleHash = makeOuterPuzzleHashForCatProgram(
        walletVector.puzzlehash,
        assetId,
        program,
      );
      outerPuzzleHashes
          .add(WalletPuzzlehash(outerPuzzleHash, walletVector.derivationIndex));

      walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
      entriesToAdd[outerPuzzleHash] = walletVector;
    }
    unhardenedMap.addAll(entriesToAdd);

    return outerPuzzleHashes.toList();
  }

  List<WalletPuzzlehash> _addOuterPuzzleHashesForAssetId(
    Puzzlehash assetId,
    Program program, {
    void Function(double progress)? onProgressUpdate,
  }) {
    final total = unhardenedMap.length;
    var added = 0;
    final outerPuzzleHashes = <WalletPuzzlehash>{};
    final entriesToAdd = <Puzzlehash, UnhardenedWalletVector>{};
    for (final walletVector in unhardenedMap.values) {
      if (walletVector.assetIdtoOuterPuzzlehash.containsKey(assetId)) {
        outerPuzzleHashes.add(
          WalletPuzzlehash(
            walletVector.assetIdtoOuterPuzzlehash[assetId]!,
            walletVector.derivationIndex,
          ),
        );
      } else {
        final outerPuzzleHash = makeOuterPuzzleHashForCatProgram(
          walletVector.puzzlehash,
          assetId,
          program,
        );

        outerPuzzleHashes.add(
          WalletPuzzlehash(outerPuzzleHash, walletVector.derivationIndex),
        );
        walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
        entriesToAdd[outerPuzzleHash] = walletVector;
      }

      added++;
      onProgressUpdate?.call(added / total);
    }
    unhardenedMap.addAll(entriesToAdd);

    return outerPuzzleHashes.toList();
  }

  static Puzzlehash makeOuterPuzzleHashForCatProgram(
    Puzzlehash innerPuzzleHash,
    Puzzlehash assetId,
    Program program,
  ) {
    final solution = Program.list([
      Program.fromAtom(program.hash()),
      Program.fromAtom(assetId),
      Program.fromAtom(innerPuzzleHash),
    ]);
    final result = curryAndTreehashProgram.run(solution);
    return Puzzlehash(result.program.atom);
  }
}

class MixedPuzzlehashes {
  MixedPuzzlehashes({
    required this.hardened,
    required this.unhardened,
    required this.outer,
  });

  MixedPuzzlehashes.fromJson(Map<String, dynamic> json)
      : hardened = (json['hardened'] as Iterable<dynamic>)
            .map(
              (dynamic e) =>
                  WalletPuzzlehash.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        unhardened = (json['unhardened'] as Iterable<dynamic>)
            .map(
              (dynamic e) =>
                  WalletPuzzlehash.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        outer = pick(json, 'outer').asJsonOrThrow().map(
              (key, value) => MapEntry(
                Puzzlehash.fromHex(key),
                pick(value).letJsonListOrThrow(WalletPuzzlehash.fromJson),
              ),
            );

  final List<WalletPuzzlehash> hardened;
  final List<WalletPuzzlehash> unhardened;

  final Map<Puzzlehash, List<WalletPuzzlehash>> outer;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'hardened': hardened.map((e) => e.toJson()).toList(),
        'unhardened': unhardened.map((e) => e.toJson()).toList(),
        'outer': outer.map(
          (key, value) =>
              MapEntry(key.toHex(), value.map((e) => e.toJson()).toList()),
        ),
      };
}

class WalletPuzzlehash extends Puzzlehash {
  WalletPuzzlehash(super.bytesList, this.derivationIndex);

  WalletPuzzlehash.fromPuzzlehash(Puzzlehash puzzlehash, this.derivationIndex)
      : super(puzzlehash.byteList);

  WalletPuzzlehash.fromJson(Map<String, dynamic> json)
      : derivationIndex = json['derivation_index'] as int,
        super(Bytes.fromHex(json['puzzlehash'] as String));

  @override
  WalletAddress toAddressWithContext() =>
      WalletAddress.fromContext(this, derivationIndex);
  @override
  WalletAddress toAddress(String ticker) =>
      WalletAddress.fromPuzzlehash(this, ticker, derivationIndex);

  final int derivationIndex;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'puzzlehash': toHex(),
        'derivation_index': derivationIndex,
      };
}

class WalletKeychainFromCoreSecretIsolateArguments {
  WalletKeychainFromCoreSecretIsolateArguments({
    required this.coreSecret,
    required this.walletSize,
    required this.plotNftWalletSize,
  });

  final KeychainCoreSecret coreSecret;
  final int walletSize;
  final int plotNftWalletSize;
}

class AddsSingletonWalletVectorArguments {
  AddsSingletonWalletVectorArguments(
    this.singletonOwnerPublicKey,
    this.masterPrivateKey,
  );

  final JacobianPoint singletonOwnerPublicKey;
  final PrivateKey masterPrivateKey;
}

class WalletAddress extends Address {
  const WalletAddress(
    super.address, {
    required this.derivationIndex,
  });
  factory WalletAddress.fromPuzzlehash(
    Puzzlehash puzzlehash,
    String addressPrefix,
    int derivationIndex,
  ) {
    final address = Address.fromPuzzlehash(puzzlehash, addressPrefix);
    return WalletAddress(address.address, derivationIndex: derivationIndex);
  }

  factory WalletAddress.fromContext(
    Puzzlehash puzzlehash,
    int derivationIndex,
  ) {
    final addressPrefix = NetworkContext().blockchainNetwork.addressPrefix;
    return WalletAddress.fromPuzzlehash(
      puzzlehash,
      addressPrefix,
      derivationIndex,
    );
  }

  final int derivationIndex;
}

extension RandomPuzzleHash on List<Puzzlehash> {
  /// get random puzzlehash in first half of derivations
  Puzzlehash get random {
    if (length < 25) {
      return getRandomItem();
    }
    return sublist(0, (length ~/ 2) - 1).getRandomItem();
  }
}
