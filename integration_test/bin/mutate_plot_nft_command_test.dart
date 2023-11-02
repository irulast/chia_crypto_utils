@Timeout(Duration(minutes: 3))

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:test_process/test_process.dart';

import 'test_process_extension.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  const poolUrl = 'https://xch.spacefarmers.io';

  final poolWalletService = PlotNftWalletService();

  test('should mutate ploft nft to leave pool', () async {
    final grant = ChiaEnthusiast(fullNodeSimulator);
    await grant.farmCoins();

    final mnemonicString = grant.keychainSecret.mnemonicString;

    final genesisCoin = grant.standardCoins[0];
    final singletonWalletVector = grant.keychain
        .getNextSingletonWalletVector(grant.keychainSecret.masterPrivateKey);

    final poolInfo = await PoolInterface.fromURL(poolUrl).getPoolInfo();
    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: poolInfo.targetPuzzlehash,
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
    );

    final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: grant.keychain,
      coins: grant.standardCoins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: grant.firstPuzzlehash,
      changePuzzlehash: grant.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await grant.refreshCoins();

    final launcherCoinPrototype =
        PlotNftWalletService.makeLauncherCoin(genesisCoin.id);

    final launcherId = launcherCoinPrototype.id;

    final process = await TestProcess.start(
      'dart',
      [
        'bin/chia_crypto_utils.dart',
        'Mutate-PlotNFT',
        '--full-node-url',
        SimulatorUtils.defaultUrl,
        '--pool-url',
        poolUrl,
        '--mnemonic',
        mnemonicString,
      ],
    );

    final sendStdout =
        await process.waitForStdout('Please send 50 mojos to cover the fee to');

    final address = Address(sendStdout.split(':').last.trim());

    await fullNodeSimulator.farmCoins(address);

    await process.stdout.next;

    process.enter();

    fullNodeSimulator.run();

    await process.nextUntilExit();

    final mutatedPlotNft =
        await fullNodeSimulator.getPlotNftByLauncherId(launcherId);

    expect(mutatedPlotNft, isNotNull);

    expect(
      mutatedPlotNft!.poolState.poolSingletonState,
      equals(PoolSingletonState.leavingPool),
    );

    fullNodeSimulator.stop();
  });
}
