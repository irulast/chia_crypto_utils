// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:hex/hex.dart';
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

  factory WalletSet.fromPrivateKeyWithRoot(
      //  PrivateKey masterPrivateKey,
      {
    required PrivateKey rootChildPrivateKey,
    required PrivateKey rootChildPrivateKeyUnhardened,
    required int derivationIndex,
  }) {
    final childPrivateKeyHardened =
        rootWalletSkToWalletSk(rootChildPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    final hardened = WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      puzzlehash: puzzlehashHardened,
    );

    final childPrivateKeyUnhardened = rootWalletSkToWalletSkUnhardened(
        rootChildPrivateKeyUnhardened, derivationIndex);
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
class WalletVector {
  WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  }) {
    this.assetIdtoOuterPuzzlehash = assetIdtoOuterPuzzlehash ?? {};
  }

  late final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;
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

  Map<String, dynamic> toMap() {
    final assetIdtoOuterPuzzlehashMap = <String, String>{};
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[key.toHex()] = value.toHex();
    });

    final map = <String, dynamic>{};
    map['childPrivateKey'] = childPrivateKey.toHex();
    map['childPublicKey'] = childPublicKey.toHex();
    map['puzzlehash'] = puzzlehash.toHex();
    map['assetIdtoOuterPuzzlehash'] = assetIdtoOuterPuzzlehashMap;

    return map;
  }

  factory WalletVector.fromMap(Map<String, dynamic> map) {
    final childPrivateKey =
        PrivateKey.fromHex(map['childPrivateKey'] as String);
    final childPublicKey = childPrivateKey.getG1();
    final puzzlehash = Puzzlehash.fromHex(map['puzzlehash'] as String);

    final assetIdtoOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};
    final assetIdtoOuterPuzzlehash =
        map['assetIdtoOuterPuzzlehash'] as Map<String, String>;

    // ignore: cascade_invocations
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[Puzzlehash.fromHex(key)] =
          Puzzlehash.fromHex(value);
    });

    return WalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdtoOuterPuzzlehashMap,
    );
  }
}

class UnhardenedWalletVector extends WalletVector {
  UnhardenedWalletVector({
    required PrivateKey childPrivateKey,
    required JacobianPoint childPublicKey,
    required Puzzlehash puzzlehash,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  }) : super(
          childPrivateKey: childPrivateKey,
          childPublicKey: childPublicKey,
          puzzlehash: puzzlehash,
          assetIdtoOuterPuzzlehash: assetIdtoOuterPuzzlehash,
        );
}
