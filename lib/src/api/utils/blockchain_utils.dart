import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BlockchainUtils {
  BlockchainUtils(this.fullNode, {LoggingFunction? logger}) : _logger = logger;
  BlockchainUtils.fromContext({LoggingFunction? logger})
      : fullNode = ChiaFullNodeInterface.fromContext(),
        _logger = logger;

  final ChiaFullNodeInterface fullNode;
  final _defaultLogger = LoggingContext().info;
  final LoggingFunction? _logger;
  LoggingFunction get logger => _logger ?? _defaultLogger;

  Future<List<Coin>> waitForTransactions(
    List<Bytes> parentCoinIds, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String waitingMessage = 'waiting for transactions to be included',
  }) async {
    final unspentIds = Set<Bytes>.from(parentCoinIds);
    final allSpentCoins = <Coin>[];

    while (unspentIds.isNotEmpty) {
      logger(waitingMessage);

      final coins = await fullNode.getCoinsByIds(unspentIds.toList(), includeSpentCoins: true);

      final spentCoins = coins.where((coin) => coin.isSpent);

      allSpentCoins.addAll(spentCoins);

      final spentIds = spentCoins.map((c) => c.id).toSet();
      unspentIds.removeWhere(spentIds.contains);

      await Future<void>.delayed(coinSearchWaitPeriod);
    }
    return allSpentCoins;
  }
}
