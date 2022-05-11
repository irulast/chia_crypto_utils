import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/pool_state.dart';
import 'package:chia_utils/src/pool/service/wallet.dart';

class PlotNft {
  PlotNft(this.singletonCoin, this.poolState, this.launcherId);
  final CoinPrototype singletonCoin;
  final PoolState poolState;
  final Bytes launcherId;

  factory PlotNft.fromCoinSpend(CoinSpend singletonCoinSpend, Bytes launcherId) {
    final poolState = PoolWalletService.coinSpendToPoolState(singletonCoinSpend);
    if (poolState == null) {
      throw ArgumentError('Provided coin spend is not a valid plot nft coin spend');
    }
    final singletonCoin = singletonCoinSpend.additions.singleWhere(
      (cs) => cs.amount == 1,
    );


    return PlotNft(singletonCoin, poolState, launcherId);
  }
}
