@Skip('interacts with mainnet')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'FULL_NODE_URL',
  );

  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  test('good generated plot nft', () async {
    final launcherId = Bytes.fromHex(
      'c36804a72e3037d2766d166fef7534f8ac21e40d24255d80ae872a748fb021bf',
    );

    final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);

    final singletonCoin = await fullNode.getCoinById(plotNft!.singletonCoin.id);
    expect(singletonCoin!.spentBlockIndex, equals(0));
  });

  test('chia plot nft', () async {
    final launcherId = Puzzlehash.fromHex(
      '389cbcd14da65522ee28254a1c2123cc4fbf0001ad7c957876bab88e4828b222',
    );

    final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);

    final singletonCoin = await fullNode.getCoinById(plotNft!.singletonCoin.id);
    expect(singletonCoin!.spentBlockIndex, equals(0));
  });
}
