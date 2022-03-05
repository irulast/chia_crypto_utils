import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';

class WalletSet {
  WalletVector hardened;
  WalletVector unhardened;
  int derivationIndex;

  WalletSet({
    required this.hardened,
    required this.unhardened,
    required this.derivationIndex
  });

  factory WalletSet.fromPrivateKey(PrivateKey masterPrivateKey, int derivationIndex, {bool testnet = false}) {
    final childPrivateKeyHardened = masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    final hardened = WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      puzzlehash: puzzlehashHardened
    );
    
    final childPrivateKeyUnhardened = masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
    final childPublicKeyUnhardened = childPrivateKeyUnhardened.getG1();

    final puzzleUnhardened = getPuzzleFromPk(childPublicKeyUnhardened);
    final puzzlehashUnhardened = Puzzlehash(puzzleUnhardened.hash());

    final unhardened = WalletVector(
      childPrivateKey: childPrivateKeyUnhardened,
      childPublicKey: childPublicKeyUnhardened,
      puzzlehash: puzzlehashUnhardened
    );

    return WalletSet(hardened: hardened, unhardened: unhardened, derivationIndex: derivationIndex);
  }
}

class WalletVector {
  PrivateKey childPrivateKey;
  JacobianPoint childPublicKey;
  Puzzlehash puzzlehash;

  WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash
  });
}
