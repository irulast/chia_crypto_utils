import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/extra_data.dart';
import 'package:chia_utils/src/pool/service/wallet.dart';

class PlotNft {
  PlotNft(this.singletonCoin, this.extraData, this.launcherId);
  final CoinPrototype singletonCoin;
  final PlotNftExtraData extraData;
  final Bytes launcherId;

  factory PlotNft.fromCoinSpend(CoinSpend singletonCoinSpend, Bytes launcherId) {
    final extraData = PoolWalletService.coinSpendToExtraData(singletonCoinSpend);
    if (extraData == null) {
      throw ArgumentError('Provided coin spend is not a valid plot nft coin spend');
    }
    final singletonCoin = singletonCoinSpend.additions.singleWhere(
      (cs) => cs.amount == 1,
    );

    return PlotNft(singletonCoin, extraData, launcherId);
  }
}
