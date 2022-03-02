import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/utils/puzzlehash.dart';

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
    final puzzleHashHardened = puzzleHardened.hash();
    final addressHardened = getAddressFromPuzzle(puzzleHardened, testnet: testnet);

    final hardened = WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      address: addressHardened, 
      puzzleHash: Puzzlehash(puzzleHashHardened)
    );
    
    final childPrivateKeyUnhardened = masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
    final childPublicKeyUnhardened = childPrivateKeyUnhardened.getG1();

    final puzzleUnhardened = getPuzzleFromPk(childPublicKeyUnhardened);
    final puzzleHashUnhardened = puzzleUnhardened.hash();
    final addressUnhardened = getAddressFromPuzzle(puzzleUnhardened, testnet: testnet);

    final unhardened = WalletVector(
      childPrivateKey: childPrivateKeyUnhardened,
      childPublicKey: childPublicKeyUnhardened,
      address: addressUnhardened,
      puzzleHash: Puzzlehash(puzzleHashUnhardened)
    );

    return WalletSet(hardened: hardened, unhardened: unhardened, derivationIndex: derivationIndex);
  }
}

class WalletVector {
  PrivateKey childPrivateKey;
  JacobianPoint childPublicKey;
  String address;
  Puzzlehash puzzleHash;

  WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.address,
    required this.puzzleHash
  });
}
