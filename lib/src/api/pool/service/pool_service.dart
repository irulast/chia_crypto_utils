import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class PoolService {
  const PoolService(this.pool, this.fullNode);

  final PoolInterface pool;
  final ChiaFullNodeInterface fullNode;

  PlotNftWalletService get plotNftWalletService => PlotNftWalletService();

  Future<Bytes> createPlotNftForPool({
    required Puzzlehash p2SingletonDelayedPuzzlehash,
    required SingletonWalletVector singletonWalletVector,
    required List<CoinPrototype> coins,
    Bytes? genesisCoinId,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
  });

  Future<AddFarmerResponse> registerAsFarmerWithPool({
    required PlotNft plotNft,
    required SingletonWalletVector singletonWalletVector,
    required Puzzlehash payoutPuzzlehash,
  });

  Future<GetFarmerResponse> getFarmerInfo({
    required Bytes launcherId,
    required PrivateKey authenticationPrivateKey,
  });
}
