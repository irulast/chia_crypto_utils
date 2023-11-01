import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class BlockchainUtils {
  factory BlockchainUtils(ChiaFullNodeInterface fullNode, {LoggingFunction? logger}) =>
      _BlockchainUtils(fullNode, logger: logger);

  factory BlockchainUtils.fromContext({LoggingFunction? logger}) =>
      _BlockchainUtils(ChiaFullNodeInterface.fromContext(), logger: logger);
  Future<List<Coin>> waitForTransactions(
    List<Bytes> parentCoinIds, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for transactions to be included',
  });

  Future<List<Coin>> waitForAdditions(
    Iterable<CoinPrototype> additions, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for additions to be confirmed',
  });
}

class _BlockchainUtils implements BlockchainUtils {
  _BlockchainUtils(this.fullNode, {this.logger});

  final ChiaFullNodeInterface fullNode;
  final _defaultLogger = print;

  final LoggingFunction? logger;

  LoggingFunction get _logger => logger ?? _defaultLogger;

  @override
  Future<List<Coin>> waitForTransactions(
    List<Bytes> parentCoinIds, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for transactions to be included',
  }) async {
    final unspentIds = Set<Bytes>.from(parentCoinIds);
    final allSpentCoins = <Coin>[];

    while (unspentIds.isNotEmpty) {
      _logger(logMessage);

      final coins = await fullNode.getCoinsByIds(unspentIds.toList(), includeSpentCoins: true);

      final spentCoins = coins.where((coin) => coin.isSpent);

      allSpentCoins.addAll(spentCoins);

      final spentIds = spentCoins.map((c) => c.id).toSet();
      unspentIds.removeWhere(spentIds.contains);

      await Future<void>.delayed(coinSearchWaitPeriod);
    }
    return allSpentCoins;
  }

  @override
  Future<List<Coin>> waitForAdditions(
    Iterable<CoinPrototype> additions, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for additions to be confirmed',
  }) async {
    final unconfirmedIds = Set<Bytes>.from(additions.map((e) => e.id));
    final confirmedCoins = <Coin>[];
    final confirmedIds = <Bytes>{};

    while (unconfirmedIds.isNotEmpty) {
      final coins = await fullNode.getCoinsByIds(
        unconfirmedIds.toList(),
        includeSpentCoins: true,
      );

      confirmedCoins.addAll(coins);
      confirmedIds.addAll(coins.map((e) => e.id));

      unconfirmedIds.removeWhere(confirmedIds.contains);

      if (unconfirmedIds.isNotEmpty) {
        _logger(logMessage);
        await Future<void>.delayed(coinSearchWaitPeriod);
      }
    }
    return confirmedCoins;
  }
}

extension WaitForSpendBundle on BlockchainUtils {
  Future<List<Coin>> waitForSpendBundle(
    SpendBundle spendBundle, {
    Duration coinSearchWaitPeriod = const Duration(seconds: 19),
    String logMessage = 'waiting for spend bundle to be included',
  }) =>
      waitForAdditions(
        spendBundle.additions,
        coinSearchWaitPeriod: coinSearchWaitPeriod,
        logMessage: logMessage,
      );
}
