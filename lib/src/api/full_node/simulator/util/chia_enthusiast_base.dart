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
  final DIDWalletService didWalletService = DIDWalletService();

  List<Coin> standardCoins = [];
  List<CatCoin> catCoins = [];

  List<CatCoin> get cat1Coins => catCoins.where((c) => c.catVersion == 1).toList();
  List<CatCoin> get cat2Coins => catCoins.where((c) => c.catVersion == 2).toList();

  DidInfo? didInfo;
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
