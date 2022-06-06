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
    final singletonWalletVector =
        nathan.keychain.getNextSingletonWalletVector(nathan.keychainSecret.masterPrivateKey);

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
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

    final launcherCoinPrototype = PlotNftWalletService.makeLauncherCoin(genesisCoin.id);

    final plotNft = (await fullNodeSimulator.getPlotNftByLauncherId(launcherCoinPrototype.id))!;
    expect(
      plotNft.poolState.toHex(),
      equals(initialTargetState.toHex()),
    );
    expect(
      plotNft.delayTime,
      equals(PlotNftWalletService.defaultDelayTime),
    );
    expect(plotNft.delayPuzzlehash, equals(nathan.firstPuzzlehash));
  });

  test('should create plot nft with fee', () async {
    final genesisCoin = nathan.standardCoins[0];
    final singletonWalletVector =
        nathan.keychain.getNextSingletonWalletVector(nathan.keychainSecret.masterPrivateKey);

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
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

    final launcherCoinPrototype = PlotNftWalletService.makeLauncherCoin(genesisCoin.id);

    final plotNft = await fullNodeSimulator.getPlotNftByLauncherId(launcherCoinPrototype.id);
    expect(
      plotNft!.poolState.toHex(),
      equals(initialTargetState.toHex()),
    );
    expect(
      plotNft.delayTime,
      equals(PlotNftWalletService.defaultDelayTime),
    );
    expect(plotNft.delayPuzzlehash, equals(nathan.firstPuzzlehash));
  });

  test('should scrounge for plot nfts', () async {
    final grant = ChiaEnthusiast(fullNodeSimulator, derivations: 5);
    await grant.farmCoins();

    final singletonWalletVector =
        grant.keychain.getNextSingletonWalletVector(grant.keychainSecret.masterPrivateKey);

    final genesisCoin = grant.standardCoins[0];

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: grant.puzzlehashes[1],
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 100,
    );
    final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: grant.keychain,
      coins: grant.standardCoins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: grant.firstPuzzlehash,
      changePuzzlehash: grant.firstPuzzlehash,
      fee: 1000,
    );

    await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final plotNfts = await fullNodeSimulator.scroungeForPlotNfts(grant.puzzlehashes);
    expect(plotNfts.length, equals(1));

    final plotNft = plotNfts[0];
    expect(
      plotNft.poolState.toHex(),
      equals(initialTargetState.toHex()),
    );
    expect(
      plotNft.delayTime,
      equals(PlotNftWalletService.defaultDelayTime),
    );
    expect(plotNft.delayPuzzlehash, equals(grant.firstPuzzlehash));
  });
}
