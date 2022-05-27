// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
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
}
