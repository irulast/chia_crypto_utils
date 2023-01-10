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
      onProgressUpdate?.call(totalWalletVectorsGenerated / totalWalletVectorsToGenerate);
    }

    final masterPrivateKey = coreSecret.masterPrivateKey;
    final walletVectors = LinkedHashMap<Puzzlehash, WalletVector>();
    final unhardenedWalletVectors = LinkedHashMap<Puzzlehash, UnhardenedWalletVector>();
    for (var i = 0; i < walletSize; i++) {
      final walletVector = WalletVector.fromPrivateKey(masterPrivateKey, i);
      incrementAndCallUpdate();

      final unhardenedWalletVector = UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);
      incrementAndCallUpdate();

      walletVectors[walletVector.puzzlehash] = walletVector;
      unhardenedWalletVectors[unhardenedWalletVector.puzzlehash] = unhardenedWalletVector;
    }

    final singletonVectors = <JacobianPoint, SingletonWalletVector>{};
    for (var i = 0; i < plotNftWalletSize; i++) {
      final singletonWalletVector = SingletonWalletVector.fromMasterPrivateKey(masterPrivateKey, i);
      incrementAndCallUpdate();

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

  Map<String, dynamic> _getSingletonWalletVectorForSingletonOwnerPublicKeyTask(
    AddsSingletonWalletVectorArguments args,
  ) {
    final masterPrivateKey = args.masterPrivateKey;
    final singletonOwnerPublicKey = args.singletonOwnerPublicKey;
    const maxIndexToCheck = 1000;
    for (var i = 0; i < maxIndexToCheck; i++) {
      final singletonOwnerSecretKey = masterSkToSingletonOwnerSk(masterPrivateKey, i);
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

  Future<SingletonWalletVector> addSingletonWalletVectorForSingletonOwnerPublicKeyAsync(
    JacobianPoint singletonOwnerPublicKey,
    PrivateKey masterPrivateKey,
  ) async {
    final newSingletonWalletVector = await spawnAndWaitForIsolate(
      taskArgument: AddsSingletonWalletVectorArguments(singletonOwnerPublicKey, masterPrivateKey),
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

    singletonWalletVectorsMap[singletonOwnerPublicKey] = newSingletonWalletVector;
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
    throw Exception(
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

  List<Puzzlehash> get puzzlehashes => LinkedHashSet<Puzzlehash>.from(
        unhardenedMap.values.map<Puzzlehash>((wv) => wv.puzzlehash),
      ).toList();

  List<Puzzlehash> get puzzlehashesHardened => LinkedHashSet<Puzzlehash>.from(
        hardenedMap.values.map<Puzzlehash>((wv) => wv.puzzlehash),
      ).toList();

  List<WalletPuzzlehash> get walletPuzzlehashes => LinkedHashSet<WalletPuzzlehash>.from(
        unhardenedMap.values.map<WalletPuzzlehash>((wv) => wv.walletPuzzlehash),
      ).toList();

  List<WalletPuzzlehash> get walletPuzzlehashesHardened => LinkedHashSet<WalletPuzzlehash>.from(
        hardenedMap.values.map<WalletPuzzlehash>((wv) => wv.walletPuzzlehash),
      ).toList();

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
    final unhardenedPuzzlehashes = <WalletPuzzlehash>[];
    final hardenedPuzzlehashes = <WalletPuzzlehash>[];
    for (var i = currentDerivationIndex; i < currentDerivationIndex + numberOfPuzzleHashes; i++) {
      final walletVector = WalletVector.fromPrivateKey(masterPrivateKey, i);
      final unhardenedWalletVector = UnhardenedWalletVector.fromPrivateKey(masterPrivateKey, i);

      hardenedPuzzlehashes.add(walletVector.walletPuzzlehash);
      unhardenedPuzzlehashes.add(unhardenedWalletVector.walletPuzzlehash);

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

  HardenedAndUnhardenedPuzzleHashes.fromJson(Map<String, dynamic> json)
      : hardened = (json['hardened'] as Iterable<dynamic>)
            .map((dynamic e) => WalletPuzzlehash.fromJson(e as Map<String, dynamic>))
            .toList(),
        unhardened = (json['unhardened'] as Iterable<dynamic>)
            .map((dynamic e) => WalletPuzzlehash.fromJson(e as Map<String, dynamic>))
            .toList();

  final List<WalletPuzzlehash> hardened;
  final List<WalletPuzzlehash> unhardened;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'hardened': hardened.map((e) => e.toJson()).toList(),
        'unhardened': unhardened.map((e) => e.toJson()).toList(),
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
  WalletAddress toAddressWithContext() => WalletAddress.fromContext(this, derivationIndex);
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
  AddsSingletonWalletVectorArguments(this.singletonOwnerPublicKey, this.masterPrivateKey);

  final JacobianPoint singletonOwnerPublicKey;
  final PrivateKey masterPrivateKey;
}

class WalletAddress extends Address {
  const WalletAddress(
    super.address, {
    required this.derivationIndex,
  });

  factory WalletAddress.fromContext(Puzzlehash puzzlehash, int derivationIndex) {
    final addressPrefix = NetworkContext().blockchainNetwork.addressPrefix;
    return WalletAddress.fromPuzzlehash(puzzlehash, addressPrefix, derivationIndex);
  }

  final int derivationIndex;

  factory WalletAddress.fromPuzzlehash(
    Puzzlehash puzzlehash,
    String addressPrefix,
    int derivationIndex,
  ) {
    final address = Address.fromPuzzlehash(puzzlehash, addressPrefix);
    return WalletAddress(address.address, derivationIndex: derivationIndex);
  }
}
