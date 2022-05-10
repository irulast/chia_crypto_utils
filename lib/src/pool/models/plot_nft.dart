import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/pool_state.dart';
import 'package:chia_utils/src/pool/service/wallet.dart';

class PlotNft {
  PlotNft(this.singletonCoin, this.poolState);
  final CoinPrototype singletonCoin;
  final PoolState poolState;

  factory PlotNft.fromCoinSpend(CoinSpend singletonCoinSpend) {
    final poolState = PoolWalletService.coinSpendToPoolState(singletonCoinSpend);
    if (poolState == null) {
      throw ArgumentError('Provided coin spend is not a valid plot nft coin spend');
    }
    return PlotNft(singletonCoinSpend.coin, poolState);
  }
}
