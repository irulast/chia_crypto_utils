// ignore_for_file: lines_longer_than_80_chars

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
class WalletVector {
  const WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash,
  });

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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'child_private_key': childPrivateKey.toHex(),
    'child_public_key': childPublicKey.toHex(),
    'puzzlehash': puzzlehash.toHex(),
  };

  WalletVector.fromJson(Map<String, dynamic> json)
    : childPrivateKey = PrivateKey.fromHex(json['child_private_key'] as String),
      childPublicKey = JacobianPoint.fromHexG1(json['child_public_key'] as String),
      puzzlehash = Puzzlehash.fromHex(json['puzzlehash'] as String);
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


  @override
  Map<String, dynamic> toJson() {
    final walletVectorJson = super.toJson();
    return <String, dynamic>{
      ...walletVectorJson,
      'asset_id_to_outer_puzzlehash': assetIdtoOuterPuzzlehash.map((assetId, outerPuzzleHash) => MapEntry(assetId.toHex(), outerPuzzleHash.toHex())),
    };
  }

  factory UnhardenedWalletVector.fromJson(Map<String, dynamic> json) {
    final walletVector = WalletVector.fromJson(json);
    return UnhardenedWalletVector(
      childPrivateKey: walletVector.childPrivateKey, 
      childPublicKey: walletVector.childPublicKey, 
      puzzlehash: walletVector.puzzlehash,
      assetIdtoOuterPuzzlehash: (json['asset_id_to_outer_puzzlehash'] as Map<String, String>)
        .map(
          (assetIdHex, outerPuzzleHashHex) 
            => MapEntry(Puzzlehash.fromHex(assetIdHex), Puzzlehash.fromHex(outerPuzzleHashHex)),
        ),
    );
  }

  @override
  int get hashCode =>
      super.hashCode ^
      assetIdtoOuterPuzzlehash.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    final firstCheck = 
      other is UnhardenedWalletVector &&
        runtimeType == other.runtimeType &&
        childPrivateKey == other.childPrivateKey &&
        childPublicKey == other.childPublicKey &&
        puzzlehash == other.puzzlehash;

    if (!firstCheck) {
      return false;
    }
    // ignore: test_types_in_equals
    final otherAsUnhardenedWalletVector = other as UnhardenedWalletVector;
    for (final assetId in assetIdtoOuterPuzzlehash.keys) {
      if (otherAsUnhardenedWalletVector.assetIdtoOuterPuzzlehash[assetId] != assetIdtoOuterPuzzlehash[assetId]) {
        return false;
      }
    }
    return true;
  }
  
}
