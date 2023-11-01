import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async {
  final mnemonic =
      'sniff wrestle coin sign one expect seed spirit summer bracket choose lumber bottom risk hip jealous fold hotel baby account chest stock humor pudding'
          .split(' ');
  final keychain = WalletKeychain.fromCoreSecret(
      KeychainCoreSecret.fromMnemonic(mnemonic),
      walletSize: 50);
  LoggingContext().setLogLevel(LogLevel.low);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final fullNode =
      EnhancedChiaFullNodeInterface.fromUrl('https://chia.irulast-prod.com');

  final nfts = await fullNode.getNftRecordsByHints(keychain.puzzlehashes);

  final nft = nfts.first;

  final proofOfNft = nft.getProofOfNft(keychain);

  print(await proofOfNft.verify(fullNode));
}
