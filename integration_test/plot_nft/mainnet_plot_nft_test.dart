@Skip('interacts with mainnet')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'FULL_NODE_URL',
  );

  const fullNode = ChiaFullNodeInterface(fullNodeRpc);
  test('bad generated plot nft', () async {
    final coinId = Bytes.fromHex(
      'bb6e7a13337b2ab28313a8f5d7919b1968ff3dbfbd5b52565b9b0a877a7ec8ab',
    );

    final coin = await fullNode.getCoinById(coinId);
    final coinSpend = await fullNode.getCoinSpend(coin!);

    final launcherCoinPrototype = coinSpend!.additions.singleWhere(
      (a) => a.amount == 1,
    );

    final launcherCoin = await fullNode.getCoinById(launcherCoinPrototype.id);

    final launcherCoinSpend = await fullNode.getCoinSpend(launcherCoin!);
    expect(
      () {
        PlotNft.fromCoinSpend(launcherCoinSpend!, launcherCoin.id);
      },
      throwsArgumentError,
    );
  });
  test('good generated plot nft', () async {
    final launcherId = Bytes.fromHex(
      'c36804a72e3037d2766d166fef7534f8ac21e40d24255d80ae872a748fb021bf',
    );

    final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);

    final singletonCoin = await fullNode.getCoinById(plotNft.singletonCoin.id);
    expect(singletonCoin!.spentBlockIndex, equals(0));
  });

  test('chia plot nft', () async {
    final launcherId = Puzzlehash.fromHex(
      '389cbcd14da65522ee28254a1c2123cc4fbf0001ad7c957876bab88e4828b222',
    );

    final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);

    final singletonCoin = await fullNode.getCoinById(plotNft.singletonCoin.id);
    expect(singletonCoin!.spentBlockIndex, equals(0));
  });
}
