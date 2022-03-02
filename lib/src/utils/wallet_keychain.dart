import 'package:chia_utils/src/utils/puzzlehash.dart';
import 'package:chia_utils/src/utils/wallet_set.dart';

class WalletKeychain {
  Map<String, WalletVector> hardenedMap = <String, WalletVector>{};
  Map<String, WalletVector> unhardenedMap = <String, WalletVector>{};

  getWalletVector(Puzzlehash puzzleHash) {
    WalletVector? walletVector = unhardenedMap[puzzleHash.hex];

    if(walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzleHash.hex];
  }

  WalletKeychain(List<WalletSet> walletSets) {
    final newHardenedMap = <String, WalletVector>{};
    final newUnhardenedMap = <String, WalletVector>{};

    for(var walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzleHash.hex] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzleHash.hex] = walletSet.unhardened;
    }
    hardenedMap = newHardenedMap;
    unhardenedMap = newUnhardenedMap;
  }
}
