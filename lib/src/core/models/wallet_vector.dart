// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class WalletVector with ToBytesMixin {
  const WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash,
  });

  static const puzzlehashLength = 32;

  factory WalletVector.fromBytes(Bytes bytes) {
    var length = bytes[0];
    var left = 1;
    var right = left + length;

    final childPrivateKey = PrivateKey.fromBytes(bytes.sublist(left, right));

    length = bytes[right];
    left = right + 1;
    right = left + length;
    final childPublicKey = JacobianPoint.fromBytes(
      bytes.sublist(left, right),
      bytes[right] == 1,
    );

    length = bytes[right + 1];
    left = right + 2;
    right = left + length;

    final puzzlehash = Puzzlehash(bytes.sublist(left, right));

    return WalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
    );
  }

  factory WalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyHardened =
        masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    return WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      puzzlehash: puzzlehashHardened,
    );
  }

  final PrivateKey childPrivateKey;
  final JacobianPoint childPublicKey;
  final Puzzlehash puzzlehash;

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      childPrivateKey.hashCode ^
      childPublicKey.hashCode ^
      puzzlehash.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WalletVector &&
            runtimeType == other.runtimeType &&
            childPrivateKey == other.childPrivateKey &&
            childPublicKey == other.childPublicKey &&
            puzzlehash == other.puzzlehash;
  }

  @override
  Bytes toBytes() {
    final childPrivateKeyBytes = childPrivateKey.toBytes();
    final childPublicKeyBytes = childPublicKey.toBytes();
    final puzzlehashBytes = puzzlehash;

    return Bytes([
      childPrivateKeyBytes.length,
      ...childPrivateKeyBytes,
      childPublicKeyBytes.length,
      ...childPublicKeyBytes,
      if (childPublicKey.isExtension) 1 else 0,
      puzzlehashBytes.length,
      ...puzzlehashBytes,
    ]);
  }
}

class UnhardenedWalletVector extends WalletVector {
  UnhardenedWalletVector({
    required PrivateKey childPrivateKey,
    required JacobianPoint childPublicKey,
    required Puzzlehash puzzlehash,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  })  : assetIdtoOuterPuzzlehash =
            assetIdtoOuterPuzzlehash ?? <Puzzlehash, Puzzlehash>{},
        super(
          childPrivateKey: childPrivateKey,
          childPublicKey: childPublicKey,
          puzzlehash: puzzlehash,
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
      childPublicKey: childPublicKeyUnhardened,
      puzzlehash: puzzlehashUnhardened,
    );
  }

  @override
  Bytes toBytes() {
    final childPrivateKeyBytes = childPrivateKey.toBytes();
    final childPublicKeyBytes = childPublicKey.toBytes();
    final puzzlehashBytes = puzzlehash;

    final assetIdMapBytes = Bytes.empty;
    assetIdtoOuterPuzzlehash.forEach((assetId, outerPuzzlehash) {
      assetIdMapBytes
        ..addAll(assetId)
        ..addAll(outerPuzzlehash);
    });

    return Bytes([
      childPrivateKeyBytes.length,
      ...childPrivateKeyBytes,
      childPublicKeyBytes.length,
      ...childPublicKeyBytes,
      if (childPublicKey.isExtension) 1 else 0,
      puzzlehashBytes.length,
      ...puzzlehashBytes,
      assetIdtoOuterPuzzlehash.length,
      ...assetIdMapBytes,
    ]);
  }

  factory UnhardenedWalletVector.fromBytes(Bytes bytes) {
    var length = bytes[0];
    var left = 1;
    var right = left + length;

    final childPrivateKey = PrivateKey.fromBytes(bytes.sublist(left, right));

    length = bytes[right];
    left = right + 1;
    right = left + length;
    final childPublicKey = JacobianPoint.fromBytes(
      bytes.sublist(left, right),
      bytes[right] == 1,
    );

    length = bytes[right + 1];
    left = right + 2;
    right = left + length;

    final puzzlehash = Puzzlehash(bytes.sublist(left, right));

    length = bytes[right];
    final assetIdToOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};
    
    var assetIdLeft = right + 1;
    var assetIdRight = assetIdLeft + WalletVector.puzzlehashLength;
    var outerPuzzlehashLeft = assetIdRight;
    var outerPuzzlehashRight = outerPuzzlehashLeft + WalletVector.puzzlehashLength;
    for(var i = 0; i < length; i++) {
      final assetId = bytes.sublist(assetIdLeft, assetIdRight);
      final outerPuzzlehash = bytes.sublist(outerPuzzlehashLeft, outerPuzzlehashRight);
      assetIdToOuterPuzzlehashMap[assetId] = outerPuzzlehash;

      assetIdLeft = outerPuzzlehashRight;
      assetIdRight = assetIdLeft + WalletVector.puzzlehashLength;
      outerPuzzlehashLeft = assetIdRight;
      outerPuzzlehashRight = outerPuzzlehashLeft + WalletVector.puzzlehashLength;
    }

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdToOuterPuzzlehashMap,
    );
  }

  final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;
}
