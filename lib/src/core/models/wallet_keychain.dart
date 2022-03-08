import 'package:chia_utils/src/core/models/puzzlehash.dart';
import 'package:chia_utils/src/core/models/wallet_set.dart';

class WalletKeychain {
  Map<String, WalletVector> hardenedMap = <String, WalletVector>{};
  Map<String, WalletVector> unhardenedMap = <String, WalletVector>{};

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    final walletVector = unhardenedMap[puzzlehash.hex];

    if (walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash.hex];
  }

  WalletKeychain(List<WalletSet> walletSets) {
    final newHardenedMap = <String, WalletVector>{};
    final newUnhardenedMap = <String, WalletVector>{};

    for (final walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash.hex] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash.hex] =
          walletSet.unhardened;
    }
    hardenedMap = newHardenedMap;
    unhardenedMap = newUnhardenedMap;
  }
}
