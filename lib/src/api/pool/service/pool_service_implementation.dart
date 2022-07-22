import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PoolServiceImpl implements PoolService{
  const PoolServiceImpl(this.pool, this.fullNode);

  PoolServiceImpl.fromContext()
      : pool = PoolInterface.fromContext(),
        fullNode = ChiaFullNodeInterface.fromContext();

  @override
  final PoolInterface pool;
  @override
  final ChiaFullNodeInterface fullNode;

  @override
  PlotNftWalletService get plotNftWalletService => PlotNftWalletService();

  @override
  Future<Bytes> createPlotNftForPool({
    required Puzzlehash p2SingletonDelayedPuzzlehash,
    required SingletonWalletVector singletonWalletVector,
    required List<CoinPrototype> coins,
    Bytes? genesisCoinId,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
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
      fee: fee,
      coins: coins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: p2SingletonDelayedPuzzlehash,
      changePuzzlehash: changePuzzlehash,
    );

    await fullNode.pushTransaction(plotNftSpendBundle);

    return PlotNftWalletService.makeLauncherCoin(genesisCoin.id).id;
  }

  @override
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

  @override
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
