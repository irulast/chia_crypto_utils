@Skip('interacts with mainnet')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final fullNode = EnhancedChiaFullNodeInterface.fromUrl('FULL_NODE_URL');

  final launcherId = const Address(
          'nft1ysdwllpf63rps75faxnkf7wkpnreyls2x0hqty2emd0f6wk4a34st2ptdj')
      .toPuzzlehash();

  final chunkDid = const Address(
          'did:chia:13zkzl0jrn6x79mwgjx7q5eeplfcfl86thf5uws2ssy9w8gypt9kqse8xph')
      .toPuzzlehash();

  test('should get chunk minter did', () async {
    final mintInfo = await fullNode.getNftMintInfoForLauncherId(launcherId);
    expect(mintInfo?.minterDid, chunkDid);
  });
}
