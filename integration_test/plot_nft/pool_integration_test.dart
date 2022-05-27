import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  // set up context, services
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final poolWalletService = PlotNftWalletService();

  final nathan = ChiaEnthusiast(fullNodeSimulator, derivations: 2);
  await nathan.farmCoins();

  test('should create plot nft', () async {
    final genesisCoin = nathan.standardCoins[0];

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: nathan.firstWalletVector.childPublicKey,
      relativeLockHeight: 100,
    );
    final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: nathan.keychain,
      coins: nathan.standardCoins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: nathan.firstPuzzlehash,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();

    final launcherCoinPrototype =
        PlotNftWalletService.makeLauncherCoin(genesisCoin.id);

    final plotNft = await fullNodeSimulator
        .getPlotNftByLauncherId(launcherCoinPrototype.id);
    expect(
      plotNft.extraData.poolState.toHex(),
      equals(initialTargetState.toHex()),
    );
    expect(
      plotNft.extraData.delayTime,
      equals(PlotNftWalletService.defaultDelayTime),
    );
    expect(plotNft.extraData.delayPuzzlehash, equals(nathan.firstPuzzlehash));
  });

  test('should create plot nft with fee', () async {
    final genesisCoin = nathan.standardCoins[0];
    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: nathan.firstWalletVector.childPublicKey,
      relativeLockHeight: 100,
    );
    final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: nathan.keychain,
      coins: nathan.standardCoins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: nathan.firstPuzzlehash,
      changePuzzlehash: nathan.firstPuzzlehash,
      fee: 1000,
    );

    await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final launcherCoinPrototype =
        PlotNftWalletService.makeLauncherCoin(genesisCoin.id);

    final plotNft = await fullNodeSimulator
        .getPlotNftByLauncherId(launcherCoinPrototype.id);
    expect(
      plotNft.extraData.poolState.toHex(),
      equals(initialTargetState.toHex()),
    );
    expect(
      plotNft.extraData.delayTime,
      equals(PlotNftWalletService.defaultDelayTime),
    );
    expect(plotNft.extraData.delayPuzzlehash, equals(nathan.firstPuzzlehash));
  });
}
