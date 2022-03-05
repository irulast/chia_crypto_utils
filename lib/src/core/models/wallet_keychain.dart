import 'package:chia_utils/src/models/puzzlehash.dart';
import 'package:chia_utils/src/models/wallet_set.dart';

class WalletKeychain {
  Map<String, WalletVector> hardenedMap = <String, WalletVector>{};
  Map<String, WalletVector> unhardenedMap = <String, WalletVector>{};

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    WalletVector? walletVector = unhardenedMap[puzzlehash.hex];

    if(walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash.hex];
  }

  WalletKeychain(List<WalletSet> walletSets) {
    final newHardenedMap = <String, WalletVector>{};
    final newUnhardenedMap = <String, WalletVector>{};

    for(var walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash.hex] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash.hex] = walletSet.unhardened;
    }
    hardenedMap = newHardenedMap;
    unhardenedMap = newUnhardenedMap;
  }
}
