// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class WalletVector with ToBytesMixin {
  const WalletVector({
    required this.childPrivateKey,
    required this.puzzlehash,
    required this.derivationIndex,
  });
  factory WalletVector.fromStream(Iterator<int> iterator, int derivationIndex) {
    final childPrivateKey = PrivateKey.fromStream(iterator);
    final puzzlehash = Puzzlehash.fromStream(iterator);

    return WalletVector(
      childPrivateKey: childPrivateKey,
      puzzlehash: puzzlehash,
      derivationIndex: derivationIndex,
    );
  }

  factory WalletVector.fromBytes(Bytes bytes, int derivationIndex) {
    final iterator = bytes.iterator;
    return WalletVector.fromStream(iterator, derivationIndex);
  }

  factory WalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyHardened = masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    return WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      puzzlehash: puzzlehashHardened,
      derivationIndex: derivationIndex,
    );
  }

  final PrivateKey childPrivateKey;
  JacobianPoint get childPublicKey => childPrivateKey.getG1();
  final Puzzlehash puzzlehash;
  final int derivationIndex;

  WalletPuzzlehash get walletPuzzlehash =>
      WalletPuzzlehash.fromPuzzlehash(puzzlehash, derivationIndex);

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      childPrivateKey.hashCode ^
      childPublicKey.hashCode ^
      puzzlehash.hashCode ^
      derivationIndex.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WalletVector &&
            runtimeType == other.runtimeType &&
            childPrivateKey == other.childPrivateKey &&
            childPublicKey == other.childPublicKey &&
            puzzlehash == other.puzzlehash &&
            derivationIndex == other.derivationIndex;
  }

  @override
  Bytes toBytes() {
    return childPrivateKey.toBytes() + puzzlehash.byteList;
  }
}

class UnhardenedWalletVector extends WalletVector {
  UnhardenedWalletVector({
    required PrivateKey childPrivateKey,
    required Puzzlehash puzzlehash,
    required int derivationIndex,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  })  : assetIdtoOuterPuzzlehash = assetIdtoOuterPuzzlehash ?? <Puzzlehash, Puzzlehash>{},
        super(
          childPrivateKey: childPrivateKey,
          puzzlehash: puzzlehash,
          derivationIndex: derivationIndex,
        );

  factory UnhardenedWalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyUnhardened =
        masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
    final childPublicKeyUnhardened = childPrivateKeyUnhardened.getG1();

    final puzzleUnhardened = getPuzzleFromPk(childPublicKeyUnhardened);
    final puzzlehashUnhardened = Puzzlehash(puzzleUnhardened.hash());

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKeyUnhardened,
      puzzlehash: puzzlehashUnhardened,
      derivationIndex: derivationIndex,
    );
  }

  @override
  Bytes toBytes() {
    var bytesList = <int>[];
    bytesList += childPrivateKey.toBytes();
    bytesList += puzzlehash.byteList;

    bytesList += intTo32Bits(assetIdtoOuterPuzzlehash.length);

    assetIdtoOuterPuzzlehash.forEach((assetId, outerPuzzlehash) {
      bytesList
        ..addAll(assetId)
        ..addAll(outerPuzzlehash);
    });

    return Bytes(bytesList);
  }

  factory UnhardenedWalletVector.fromStream(Iterator<int> iterator, int derivationIndex) {
    final childPrivateKey = PrivateKey.fromStream(iterator);
    final puzzlehash = Puzzlehash.fromStream(iterator);

    final assetIdToOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};

    final assetIdMapLength = intFrom32BitsStream(iterator);

    for (var _ = 0; _ < assetIdMapLength; _++) {
      final assetId = Puzzlehash.fromStream(iterator);
      final outerPuzzlehash = Puzzlehash.fromStream(iterator);
      assetIdToOuterPuzzlehashMap[assetId] = outerPuzzlehash;
    }

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdToOuterPuzzlehashMap,
      derivationIndex: derivationIndex,
    );
  }

  factory UnhardenedWalletVector.fromBytes(Bytes bytes, int derivationIndex) {
    final iterator = bytes.iterator;
    return UnhardenedWalletVector.fromStream(iterator, derivationIndex);
  }

  @override
  int get hashCode => super.hashCode ^ assetIdtoOuterPuzzlehash.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    final firstCheck = other is UnhardenedWalletVector &&
        runtimeType == other.runtimeType &&
        childPrivateKey == other.childPrivateKey &&
        childPublicKey == other.childPublicKey &&
        puzzlehash == other.puzzlehash &&
        derivationIndex == other.derivationIndex;

    if (!firstCheck) {
      return false;
    }

    for (final assetId in assetIdtoOuterPuzzlehash.keys) {
      if (other.assetIdtoOuterPuzzlehash[assetId] != assetIdtoOuterPuzzlehash[assetId]) {
        return false;
      }
    }
    return true;
  }

  final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;
}
