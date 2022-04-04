// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

class WalletSet {
  WalletVector hardened;
  UnhardenedWalletVector unhardened;
  int derivationIndex;

  WalletSet({
    required this.hardened,
    required this.unhardened,
    required this.derivationIndex,
  });

  factory WalletSet.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyHardened =
        masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    final hardened = WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      puzzlehash: puzzlehashHardened,
    );

    final childPrivateKeyUnhardened =
        masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
    final childPublicKeyUnhardened = childPrivateKeyUnhardened.getG1();

    final puzzleUnhardened = getPuzzleFromPk(childPublicKeyUnhardened);
    final puzzlehashUnhardened = Puzzlehash(puzzleUnhardened.hash());

    final unhardened = UnhardenedWalletVector(
      childPrivateKey: childPrivateKeyUnhardened,
      childPublicKey: childPublicKeyUnhardened,
      puzzlehash: puzzlehashUnhardened,
    );

    return WalletSet(
      hardened: hardened,
      unhardened: unhardened,
      derivationIndex: derivationIndex,
    );
  }
}

@immutable
class WalletVector with ToBytesMixin {
  const WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash,
  });

  factory WalletVector.fromBytes(Uint8List bytes) {
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
  Uint8List toBytes() {
    final childPrivateKeyBytes = childPrivateKey.toBytes();
    final childPublicKeyBytes = childPublicKey.toBytes();
    final puzzlehashBytes = puzzlehash.toBytes();

    return Uint8List.fromList([
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

  final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;
}
