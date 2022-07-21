import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/add_farmer_response.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';

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
