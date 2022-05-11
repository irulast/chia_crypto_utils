import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/plot_nft.dart';
import 'package:chia_utils/src/pool/models/pool_state.dart';
import 'package:chia_utils/src/pool/service/wallet.dart';
import 'package:chia_utils/src/singleton/puzzles/singleton_launcher/singleton_launcher.clvm.hex.dart';
import 'package:test/test.dart';

import '../simulator/simulator_utils.dart';
import '../util/chia_enthusiast.dart';

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
  final poolWalletService = PoolWalletService();

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
      originId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: nathan.firstPuzzlehash,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final launcherCoinPrototype = CoinPrototype(
      parentCoinInfo: genesisCoin.id,
      puzzlehash: singletonLauncherProgram.hash(),
      amount: 1,
    );
    final launcherCoin = await fullNodeSimulator.getCoinById(launcherCoinPrototype.id);

    // print(launcherCoin);
    final launcherCoinSpend = await fullNodeSimulator.getCoinSpend(launcherCoin!);
    final plotNft = PlotNft.fromCoinSpend(launcherCoinSpend!);
    expect(plotNft.poolState.toHexChia(), equals(initialTargetState.toHexChia()));
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
      originId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: nathan.firstPuzzlehash,
      changePuzzlehash: nathan.firstPuzzlehash,
      fee: 1000,
    );

    await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final launcherCoinPrototype = CoinPrototype(
      parentCoinInfo: genesisCoin.id,
      puzzlehash: singletonLauncherProgram.hash(),
      amount: 1,
    );
    final launcherCoin = await fullNodeSimulator.getCoinById(launcherCoinPrototype.id);

    // print(launcherCoin);
    final launcherCoinSpend = await fullNodeSimulator.getCoinSpend(launcherCoin!);
    final plotNft = PlotNft.fromCoinSpend(launcherCoinSpend!);
    expect(plotNft.poolState.toHexChia(), equals(initialTargetState.toHexChia()));
  });
}
