import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/add_farmer_response.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';

class PoolService {
  const PoolService(this.pool, this.fullNode);

  PoolService.fromContext()
      : pool = PoolInterface.fromContext(),
        fullNode = ChiaFullNodeInterface.fromContext();

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
  }) async {
    final poolInfo = await pool.getPoolInfo();

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: poolInfo.relativeLockHeight,
      poolUrl: pool.poolUrl,
    );

    final genesisCoin =
        (genesisCoinId != null) ? coins.singleWhere((c) => c.id == genesisCoinId) : coins[0];

    final plotNftSpendBundle = plotNftWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: keychain,
      fee: 50,
      coins: coins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: p2SingletonDelayedPuzzlehash,
      changePuzzlehash: changePuzzlehash,
    );

    await fullNode.pushTransaction(plotNftSpendBundle);

    return PlotNftWalletService.makeLauncherCoin(genesisCoin.id).id;
  }

  Future<AddFarmerResponse> registerAsFarmerWithPool({
    required PlotNft plotNft,
    required SingletonWalletVector singletonWalletVector,
    required Puzzlehash payoutPuzzlehash,
  }) async {
    if (singletonWalletVector.singletonOwnerPublicKey != plotNft.poolState.ownerPublicKey) {
      throw ArgumentError(
        'Provided SingletonWalletVector does not match plotNft owner public key',
      );
    }

    final poolInfo = await pool.getPoolInfo();

    return pool.addFarmer(
      launcherId: plotNft.launcherId,
      authenticationToken: getCurrentAuthenticationToken(poolInfo.authenticationTokenTimeout),
      authenticationPublicKey: singletonWalletVector.poolingAuthenticationPublicKey,
      payoutPuzzlehash: payoutPuzzlehash,
      singletonOwnerPrivateKey: singletonWalletVector.singletonOwnerPrivateKey,
    );
  }

  Future<GetFarmerResponse> getFarmerInfo({
    required Bytes launcherId,
    required PrivateKey authenticationPrivateKey,
  }) async {
    final poolInfo = await pool.getPoolInfo();

    final authenticationToken = getCurrentAuthenticationToken(poolInfo.authenticationTokenTimeout);

    return pool.getFarmer(
      launcherId: launcherId,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      authenticationToken: authenticationToken,
      authenticationSecretKey: authenticationPrivateKey,
    );
  }

  static int getCurrentAuthenticationToken(int timeout) {
    final secondsSinceEpoch = DateTime.now().millisecondsSinceEpoch / 1000;
    return ((secondsSinceEpoch / 60).floor() / timeout).floor();
  }
}
