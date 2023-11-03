@Skip('interacts with live full node')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  const url = 'FULL_NODE_URL';
  const mnemonicString = 'MNEMONIC_STRING';

  final mnemonic = mnemonicString.split(' ');
  final keychain = WalletKeychain.fromCoreSecret(
    KeychainCoreSecret.fromMnemonic(mnemonic),
    walletSize: 50,
  );
  LoggingContext().setLogLevel(LogLevel.low);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final fullNode = EnhancedChiaFullNodeInterface.fromUrl(url);

  final nfts = await fullNode.getNftRecordsByHints(keychain.puzzlehashes);

  final nft = nfts.first;

  final proofOfNft = nft.getProofOfNft(keychain);

  test('should verify nft', () async {
    final verificationResult = await proofOfNft.verify(fullNode);

    print(verificationResult);
  });
}
