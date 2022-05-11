@Skip('interacts with mainnet')
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/plot_nft.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'FULL_NODE_URL',
  );

  const fullNode = ChiaFullNodeInterface(fullNodeRpc);
  test('generated plot nft', () async {
    final coinId =
        Bytes.fromHex('bb6e7a13337b2ab28313a8f5d7919b1968ff3dbfbd5b52565b9b0a877a7ec8ab');

    final coin = await fullNode.getCoinById(coinId);
    final coinSpend = await fullNode.getCoinSpend(coin!);

    final launcherCoinPrototype = coinSpend!.additions.singleWhere(
      (a) => a.amount == 1,
    );

    final launcherCoin = await fullNode.getCoinById(launcherCoinPrototype.id);

    final launcherCoinSpend = await fullNode.getCoinSpend(launcherCoin!);
    print(launcherCoinSpend!.solution);

  });

  test('chia plot nft', () async {
    final launcherId =
        Puzzlehash.fromHex('389cbcd14da65522ee28254a1c2123cc4fbf0001ad7c957876bab88e4828b222');
    final launcherCoin = await fullNode.getCoinById(launcherId);
    final launcherSpend = await fullNode.getCoinSpend(launcherCoin!);
    final plotNft = PlotNft.fromCoinSpend(launcherSpend!);
    print(plotNft.poolState);
  });
}
