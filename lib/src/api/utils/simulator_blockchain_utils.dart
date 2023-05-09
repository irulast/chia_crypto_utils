import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SimulatorBlockchainUtils implements BlockchainUtils {
  SimulatorBlockchainUtils(this.simulator);

  final SimulatorFullNodeInterface simulator;

  @override
  Future<List<Coin>> waitForAdditions(
    Iterable<CoinPrototype> additions, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for additions to be confirmed',
  }) async {
    await simulator.moveToNextBlock();

    return simulator.getCoinsByIds(additions.map((e) => e.id).toList());
  }

  @override
  Future<List<Coin>> waitForTransactions(
    List<Bytes> parentCoinIds, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for transactions to be included',
  }) async {
    await simulator.moveToNextBlock();
    final coins = await simulator.getCoinsByIds(parentCoinIds, includeSpentCoins: true);
    if (parentCoinIds.length != coins.length) {
      throw Exception('was goin on');
    }
    return coins;
  }
}
