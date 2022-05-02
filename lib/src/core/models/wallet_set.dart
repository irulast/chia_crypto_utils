// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class WalletSet {
  const WalletSet({
    required this.hardened,
    required this.unhardened,
    required this.derivationIndex,
  });

  factory WalletSet.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    return WalletSet(
      hardened: WalletVector.fromPrivateKey(
        masterPrivateKey,
        derivationIndex,
      ),
      unhardened: UnhardenedWalletVector.fromPrivateKey(
        masterPrivateKey,
        derivationIndex,
      ),
      derivationIndex: derivationIndex,
    );
  }

  final WalletVector hardened;
  final UnhardenedWalletVector unhardened;
  final int derivationIndex;

  factory WalletSet.fromPrivateKeyWithRoot({
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
  Map<String, dynamic> toMap() => <String, dynamic>{
        'hardened': hardened.toMap(),
        'unhardened': unhardened.toMap(),
        'derivationIndex': derivationIndex,
      };

  factory WalletSet.fromMap(Map<String, dynamic> mapData) {
    final derivationIndex = mapData['derivationIndex'] as int;
    final hardenedMap = mapData['hardened'] as Map<String, dynamic>;
    final unhardenedMap = mapData['unhardened'] as Map<String, dynamic>;
    final _hardened = WalletVector.fromMap(hardenedMap);
    final unhardened = UnhardenedWalletVector.fromMap(unhardenedMap);

    return WalletSet(
      hardened: _hardened,
      unhardened: unhardened,
      derivationIndex: derivationIndex,
    );
  }
}
