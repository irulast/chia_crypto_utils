import 'package:chia_utils/chia_crypto_utils.dart';

class PlotNft with ToBytesMixin {
  PlotNft(this.singletonCoin, this.extraData, this.launcherId);
  final CoinPrototype singletonCoin;
  final PlotNftExtraData extraData;
  final Bytes launcherId;

  factory PlotNft.fromCoinSpend(CoinSpend singletonCoinSpend, Bytes launcherId) {
    final extraData = PlotNftWalletService.coinSpendToExtraData(singletonCoinSpend);
    if (extraData == null) {
      throw ArgumentError('Provided coin spend is not a valid plot nft coin spend');
    }
    final singletonCoin = singletonCoinSpend.additions.singleWhere(
      (cs) => cs.amount == 1,
    );

    return PlotNft(singletonCoin, extraData, launcherId);
  }

  factory PlotNft.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    final singletonCoin = CoinPrototype.fromStream(iterator);
    final plotNftExtraData = PlotNftExtraData.fromStream(iterator);
    final launcherId = Puzzlehash.fromStream(iterator);

    return PlotNft(singletonCoin, plotNftExtraData, launcherId);
  }

  @override
  Bytes toBytes() {
    return singletonCoin.toBytes() + extraData.toBytes() + launcherId;
  }
}
