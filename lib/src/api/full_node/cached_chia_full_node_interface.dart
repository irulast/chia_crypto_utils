import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_cache.dart';

class CachedChiaFullNodeInterface extends ChiaFullNodeInterface {
  factory CachedChiaFullNodeInterface(
      ChiaFullNodeInterface delegate, FullNodeCache cache) {
    return CachedChiaFullNodeInterface._(delegate.fullNode, delegate, cache);
  }
  CachedChiaFullNodeInterface._(super.fullNode, this.delegate, this.cache);
  final ChiaFullNodeInterface delegate;

  final FullNodeCache cache;

  @override
  Future<CoinSpend?> getParentSpend(Coin coin) async {
    final fromCache = cache.getParentSpend(coin.id);
    if (fromCache != null) {
      LoggingContext().error('returned cached coin spend');
      return fromCache;
    }
    final fromDelegate = await delegate.getParentSpend(coin);
    if (fromDelegate != null) {
      await cache.addParentSpend(coin.id, fromDelegate);
    }
    return fromDelegate;
  }
}
