import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/puzzles/return_conditions/return_conditions.clvm.hex.dart';
import 'package:test/test.dart';

Future<void> main() async {
  SimulatorUtils.simulatorGeneratedFilesPathOverride = '/Users/nvjoshi/.chia-simulator-enhanced';
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

  final nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 3);
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
    final grant = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);
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

  test('should create and scrounge for multiple plot nfts', () async {
    final meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    for (var i = 0; i < 4; i++) {
      await meera.farmCoins();

      final singletonWalletVector =
          meera.keychain.getNextSingletonWalletVector(meera.keychainSecret.masterPrivateKey);

      final genesisCoin = meera.standardCoins[0];

      final initialTargetState = PoolState(
        poolSingletonState: PoolSingletonState.selfPooling,
        targetPuzzlehash: meera.puzzlehashes[i],
        ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
        relativeLockHeight: 100,
      );

      final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
        initialTargetState: initialTargetState,
        keychain: meera.keychain,
        coins: meera.standardCoins,
        genesisCoinId: genesisCoin.id,
        p2SingletonDelayedPuzzlehash: meera.firstPuzzlehash,
        changePuzzlehash: meera.firstPuzzlehash,
      );

      await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
      await fullNodeSimulator.moveToNextBlock();
      await meera.refreshCoins();

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
      expect(plotNft.delayPuzzlehash, equals(meera.firstPuzzlehash));
    }

    final plotNfts = await fullNodeSimulator.scroungeForPlotNfts(meera.puzzlehashes);
    expect(plotNfts.length, equals(4));
  });

  test('should create and mutate plot nft', () async {
    const poolUrl = 'https://xch-us-west.flexpool.io';
    final pool = PoolInterface.fromURL(poolUrl);

    final poolInfo = await pool.getPoolInfo();

    final genesisCoin = nathan.standardCoins[0];
    final singletonWalletVector =
        nathan.keychain.getNextSingletonWalletVector(nathan.keychainSecret.masterPrivateKey);

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
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

    await nathan.farmCoins();
    await nathan.refreshCoins();

    final targetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 100,
      poolUrl: poolUrl,
    );

    final plotNftMutationSpendBundle = await poolWalletService.createPlotNftMutationSpendBundle(
      plotNft: plotNft,
      targetState: targetState,
      keychain: nathan.keychain,
    );

    await fullNodeSimulator.pushTransaction(plotNftMutationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();

    final mutatedPlotNft =
        (await fullNodeSimulator.getPlotNftByLauncherId(launcherCoinPrototype.id))!;

    expect(
      mutatedPlotNft.poolState.toHex(),
      equals(targetState.toHex()),
    );
  });

  test('should create plot nft in farmingToPool state, leave pool, and transfer ownership',
      () async {
    final genesisCoin = nathan.standardCoins[0];
    final singletonWalletVector =
        nathan.keychain.getNextSingletonWalletVector(nathan.keychainSecret.masterPrivateKey);

    final poolInfo = await PoolInterface.fromURL('https://xch-us-west.flexpool.io').getPoolInfo();
    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
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

    await nathan.farmCoins();
    await nathan.refreshCoins();

    final meera = ChiaEnthusiast(fullNodeSimulator);

    final meeraSingletonWalletVector =
        meera.keychain.getNextSingletonWalletVector(meera.keychainSecret.masterPrivateKey);

    final targetState = PoolState(
      poolSingletonState: PoolSingletonState.leavingPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
    );

    final plotNftMutationSpendBundle = await poolWalletService.createPlotNftMutationSpendBundle(
      plotNft: plotNft,
      targetState: targetState,
      keychain: nathan.keychain,
    );

    await fullNodeSimulator.pushTransaction(plotNftMutationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();

    final leftPoolPlotNft =
        (await fullNodeSimulator.getPlotNftByLauncherId(launcherCoinPrototype.id))!;

    expect(
      leftPoolPlotNft.poolState.toHex(),
      equals(targetState.toHex()),
    );

    final transferTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: meeraSingletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: poolInfo.relativeLockHeight,
      poolUrl: 'https://xch-us-west.flexpool.io',
    );

    final transferAndJoinPoolSpendBundle = await poolWalletService.createTransferPlotNftSpendBundle(
      coins: nathan.standardCoins,
      plotNft: leftPoolPlotNft,
      targetOwnerPublicKey: meeraSingletonWalletVector.singletonOwnerPublicKey,
      keychain: nathan.keychain,
      newPoolSingletonState: PoolSingletonState.farmingToPool,
      changePuzzleHash: nathan.firstPuzzlehash,
      poolUrl: transferTargetState.poolUrl,
    );

    await fullNodeSimulator.pushTransaction(transferAndJoinPoolSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();

    final plotNftTreasureMapCoin = (await fullNodeSimulator.getCoinsByMemo(
      meeraSingletonWalletVector.plotNftHint,
    ))
        .single;

    final transferredPlotNft =
        await fullNodeSimulator.getPlotNftByLauncherId(plotNftTreasureMapCoin.puzzlehash);

    expect(
      transferredPlotNft!.poolState.toHex(),
      equals(transferTargetState.toHex()),
    );
  });

  test(
      'should create plot nft in selfPooling state and transfer ownership no  with treasure map spend',
      () async {
    final genesisCoin = nathan.standardCoins[0];
    final singletonWalletVector =
        nathan.keychain.getNextSingletonWalletVector(nathan.keychainSecret.masterPrivateKey);

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
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

    await nathan.farmCoins();
    await nathan.refreshCoins();

    final meera = ChiaEnthusiast(fullNodeSimulator);

    final meeraSingletonWalletVector =
        meera.keychain.getNextSingletonWalletVector(meera.keychainSecret.masterPrivateKey);

    const poolUrl = 'https://xch-us-west.flexpool.io';
    final poolInfo = await PoolInterface.fromURL(poolUrl).getPoolInfo();

    final transferTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: meeraSingletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: poolInfo.relativeLockHeight,
      poolUrl: poolUrl,
    );

    final transferSpendBundle = await poolWalletService.createTransferPlotNftSpendBundle(
      coins: nathan.standardCoins,
      plotNft: plotNft,
      targetOwnerPublicKey: meeraSingletonWalletVector.singletonOwnerPublicKey,
      keychain: nathan.keychain,
      newPoolSingletonState: PoolSingletonState.farmingToPool,
      changePuzzleHash: nathan.firstPuzzlehash,
      poolUrl: transferTargetState.poolUrl,
    );

    await fullNodeSimulator.pushTransaction(transferSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();

    final plotNftTreasureMapCoin = (await fullNodeSimulator.getCoinsByMemo(
      meeraSingletonWalletVector.plotNftHint,
    ))
        .single;

    final transferredPlotNft =
        await fullNodeSimulator.getPlotNftByLauncherId(plotNftTreasureMapCoin.puzzlehash);

    expect(
      transferredPlotNft!.poolState.toHex(),
      equals(transferTargetState.toHex()),
    );
  });

  test('should create plot nft in selfPooling state and transfer ownership', () async {
    final genesisCoin = nathan.standardCoins[0];
    final singletonWalletVector =
        nathan.keychain.getNextSingletonWalletVector(nathan.keychainSecret.masterPrivateKey);

    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
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

    await nathan.farmCoins();
    await nathan.refreshCoins();

    final meera = ChiaEnthusiast(fullNodeSimulator);

    final meeraSingletonWalletVector =
        meera.keychain.getNextSingletonWalletVector(meera.keychainSecret.masterPrivateKey);

    const poolUrl = 'https://xch-us-west.flexpool.io';
    final poolInfo = await PoolInterface.fromURL(poolUrl).getPoolInfo();

    final transferTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: meeraSingletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: poolInfo.relativeLockHeight,
      poolUrl: poolUrl,
    );

    final transferSpendBundle = await poolWalletService.createPlotNftTransferSpendBundle(
      plotNft: plotNft,
      receiverPuzzlhash: meera.firstPuzzlehash,
      keychain: nathan.keychain,
      changePuzzleHash: nathan.firstPuzzlehash,
      targetState: transferTargetState,
    );
    print('--------\n');
    transferSpendBundle.debug();

    await fullNodeSimulator.pushTransaction(transferSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();

    final puzzleAsh =
        SingletonService.puzzleForSingleton(plotNft.launcherId, returnConditionsProgram).hash();

    final coin = await fullNodeSimulator.getCoinsByPuzzleHashes([puzzleAsh]);
    print(coin);
    // final plotNftCoin = (await fullNodeSimulator.getCoinsByMemo(
    //   meera.firstPuzzlehash,
    // ))
    //     .single;

    // final transferredPlotNft =
    //     await fullNodeSimulator.getPlotNftByLauncherId(plotNftTreasureMapCoin.puzzlehash);

    // expect(
    //   transferredPlotNft!.poolState.toHex(),
    //   equals(transferTargetState.toHex()),
    // );
  });
}
