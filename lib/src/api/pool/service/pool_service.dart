import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/authentication_payload.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_payload.dart';
import 'package:chia_crypto_utils/src/api/pool/pool_interface.dart';

class PoolService {
  const PoolService(this.poolInterface, this.fullNode);
  final PoolInterface poolInterface;
  final ChiaFullNodeInterface fullNode;

  PlotNftWalletService get plotNftWalletService => PlotNftWalletService();

  Future<Bytes> createPlotNftForPool({
    required Puzzlehash p2SingletonDelayedPuzzlehash,
    required PrivateKey masterPrivateKey,
    required int singletonOwnerPrivateKeyDerivationIndex,
    required List<CoinPrototype> coins,
    Bytes? genesisCoinId,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
  }) async {
    final singletonOwnerSecretKey = masterSkToSingletonOwnerSk(
      masterPrivateKey,
      singletonOwnerPrivateKeyDerivationIndex,
    );

    final poolInfo = await poolInterface.getPoolInfo();

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: singletonOwnerSecretKey.getG1(),
      relativeLockHeight: poolInfo.relativeLockHeight,
      poolUrl: poolInterface.poolUrl,
    );

    final genesisCoin =
        (genesisCoinId != null) ? coins.singleWhere((c) => c.id == genesisCoinId) : coins[0];

    final plotNftSpendBundle = plotNftWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: keychain,
      coins: coins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: p2SingletonDelayedPuzzlehash,
      changePuzzlehash: changePuzzlehash,
    );

    await fullNode.pushTransaction(plotNftSpendBundle);

    return PlotNftWalletService.makeLauncherCoin(genesisCoin.id).id;
  }

  Future<void> registerPlotNftWithPool({
    required PlotNft plotNft,
    required PrivateKey masterPrivateKey,
    required int singletonOwnerPrivateKeyDerivationIndex,
    required Puzzlehash payoutPuzzlehash,
  }) async {
    // will probably need SingletonWalletVector(index, singletonOwnerSecretKey, authenticationSecretKey)
    final authenticationSecretKey = masterSkToPoolingAuthenticationSk(
      masterPrivateKey,
      singletonOwnerPrivateKeyDerivationIndex,
      0,
    );

    final singletonOwnerSecretKey = masterSkToSingletonOwnerSk(
      masterPrivateKey,
      singletonOwnerPrivateKeyDerivationIndex,
    );

    if (singletonOwnerSecretKey.getG1() != plotNft.extraData.poolState.ownerPublicKey) {
      throw ArgumentError(
          'Provided singleton owner secret key does not match plotNft owner public key');
    }

    final poolInfo = await poolInterface.getPoolInfo();

    final payload = PostFarmerPayload(
      launcherId: plotNft.launcherId,
      authenticationToken: getCurrentAuthenticationToken(poolInfo.authenticationTokenTimeout),
      authenticationPublicKey: authenticationSecretKey.getG1(),
      payoutPuzzlehash: payoutPuzzlehash,
    );

    final signature = AugSchemeMPL.sign(
      singletonOwnerSecretKey,
      payload.toBytes().sha256Hash(),
    );

    await poolInterface.addFarmer(payload, signature);
  }

  Future<void> getFarmer({
    required Bytes launcherId,
    required PrivateKey masterPrivateKey,
    required int singletonOwnerPrivateKeyDerivationIndex,
  }) async {
    final authenticationSecretKey = masterSkToPoolingAuthenticationSk(
      masterPrivateKey,
      singletonOwnerPrivateKeyDerivationIndex,
      0,
    );

    final poolInfo = await poolInterface.getPoolInfo();

    final authenticationToken = getCurrentAuthenticationToken(poolInfo.authenticationTokenTimeout);

    final authenticationPayload = AuthenticationPayload(
      endpoint: AuthenticationEndpoint.getFarmer,
      launcherId: launcherId,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      authenticationToken: authenticationToken,
    );

    final message = authenticationPayload.toBytes().sha256Hash();

    final signature = AugSchemeMPL.sign(authenticationSecretKey, message);
    await poolInterface.getFarmer(launcherId, authenticationToken, signature);
  }

  // def get_current_authentication_token(timeout: uint8) -> uint64:
  //   return uint64(int(int(time.time() / 60) / timeout))
  static int getCurrentAuthenticationToken(int timeout) {
    final secondsSinceEpoch = DateTime.now().millisecondsSinceEpoch / 1000;
    return ((secondsSinceEpoch / 60).floor() / timeout).floor();
  }
}
