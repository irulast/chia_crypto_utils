import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:get_it/get_it.dart';

class ChiaEnthusiastBase {
  ChiaEnthusiastBase({
    List<String>? mnemonic,
    int walletSize = 1,
    int plotNftWalletSize = 2,
  }) {
    keychainSecret = mnemonic != null
        ? KeychainCoreSecret.fromMnemonic(mnemonic)
        : KeychainCoreSecret.generate();

    keychain = WalletKeychain.fromCoreSecret(
      keychainSecret,
      walletSize: walletSize,
      plotNftWalletSize: plotNftWalletSize,
    );
  }
  final Cat1WalletService cat1WalletService = Cat1WalletService();
  final Cat2WalletService catWalletService = Cat2WalletService();
  List<Coin> standardCoins = [];
  List<CatCoin> cat1Coins = [];
  List<CatCoin> catCoins = [];
  late WalletKeychain keychain;
  late KeychainCoreSecret keychainSecret;

  List<Puzzlehash> get puzzlehashes =>
      keychain.unhardenedMap.values.map((wv) => wv.puzzlehash).toList();

  List<Puzzlehash> get outerPuzzlehashes => keychain.unhardenedMap.values.fold(
        <Puzzlehash>[],
        (previousValue, wv) => previousValue + wv.assetIdtoOuterPuzzlehash.values.toList(),
      );

  UnhardenedWalletVector get firstWalletVector => keychain.unhardenedMap.values.first;

  Puzzlehash get firstPuzzlehash => firstWalletVector.puzzlehash;

  Address get address => Address.fromPuzzlehash(
        firstWalletVector.puzzlehash,
        GetIt.I.get<BlockchainNetwork>().addressPrefix,
      );
}
