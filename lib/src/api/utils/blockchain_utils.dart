import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BlockchainUtils {
  BlockchainUtils(this.fullNode);
  BlockchainUtils.fromContext() : fullNode = ChiaFullNodeInterface.fromContext();

  final ChiaFullNodeInterface fullNode;
  final logger = LoggingContext().info;

  Future<List<Coin>> waitForTransactions(List<Bytes> parentCoinIds) async {
    final unspentIds = Set<Bytes>.from(parentCoinIds);
    final allSpentCoins = <Coin>[];

    while (unspentIds.isNotEmpty) {
      logger('waiting for transactions to be included...');

      final coins = await fullNode.getCoinsByIds(unspentIds.toList(), includeSpentCoins: true);

      final spentCoins = coins.where((coin) => coin.isSpent);

      allSpentCoins.addAll(spentCoins);

      final spentIds = spentCoins.map((c) => c.id).toSet();
      unspentIds.removeWhere(spentIds.contains);

      await Future<void>.delayed(const Duration(seconds: 19));
    }
    return allSpentCoins;
  }
}
