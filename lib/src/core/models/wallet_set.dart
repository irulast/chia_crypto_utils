import 'package:chia_utils/chia_crypto_utils.dart';

class WalletSet {
  WalletVector hardened;
  UnhardenedWalletVector unhardened;
  int derivationIndex;

  WalletSet({
    required this.hardened,
    required this.unhardened,
    required this.derivationIndex,
  });

  factory WalletSet.fromPrivateKey(PrivateKey masterPrivateKey, int derivationIndex) {
    final childPrivateKeyHardened = masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    final hardened = WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      puzzlehash: puzzlehashHardened,
    );

    final childPrivateKeyUnhardened = masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
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

class WalletVector {
  PrivateKey childPrivateKey;
  JacobianPoint childPublicKey;
  Puzzlehash puzzlehash;

  WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash,
  });
}

class UnhardenedWalletVector extends WalletVector{
  Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash = {};
 
  UnhardenedWalletVector({
    required PrivateKey childPrivateKey,
    required JacobianPoint childPublicKey,
    required Puzzlehash puzzlehash,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  }) : super(
    childPrivateKey: childPrivateKey,
    childPublicKey: childPublicKey,
    puzzlehash: puzzlehash,
  ) {
    assetIdtoOuterPuzzlehash = assetIdtoOuterPuzzlehash ?? {};
  }
}
