import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/plot_nft.dart';
import 'package:chia_utils/src/singleton/puzzles/singleton_launcher/singleton_launcher.clvm.hex.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'https://chia.irulast-prod.com',
  );
  // LoggingContext().setLogLevel(LogLevel.low);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  final coinId = Bytes.fromHex('bb6e7a13337b2ab28313a8f5d7919b1968ff3dbfbd5b52565b9b0a877a7ec8ab');

  final coin = await fullNode.getCoinById(coinId);
  final coinSpend = await fullNode.getCoinSpend(coin!);
  print(coinSpend!.solution.rest().rest().first());
  // PlotNft.fromCoinSpend(coinSpend!);

  final launcherCoinPrototype = coinSpend!.additions.singleWhere(
    (a) => a.amount == 1,
  );
  // print(launcherCoinPrototype.id);
  final launcherCoin = await fullNode.getCoinById(launcherCoinPrototype.id);
  // print(launcherCoin);
  final launcherCoinSpend = await fullNode.getCoinSpend(launcherCoin!);
  print(launcherCoinSpend!.solution.rest().rest().first());
  // PlotNft.fromCoinSpend(launcherCoinSpend!);

  // final singletonCoinPrototype = launcherCoinSpend!.additions[0];
  // final singletonCoin = await fullNode.getCoinById(singletonCoinPrototype.id);
  // print(singletonCoin);
}
