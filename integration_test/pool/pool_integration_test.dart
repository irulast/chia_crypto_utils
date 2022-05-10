import 'package:chia_utils/chia_crypto_utils.dart';
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
  final mnemonic = 'leader fresh forest lady decline soup twin crime remember doll push hip fox future arctic easy rent roast ketchup skin hip crane dilemma whip'.split(' ');

  final nathan = ChiaEnthusiast(fullNodeSimulator, mnemonic: mnemonic,derivations: 2);
  await nathan.farmCoins();

  test('should create plot nft', () async {
    final genesisCoin = nathan.standardCoins[0];
    final initialTargetState = PoolState(
      version: 1,
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: nathan.puzzlehashes[1],
      ownerPublicKey: nathan.firstWalletVector.childPublicKey,
      relativeLockHeight: 100,
    );
    final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: nathan.keychain,
      coins: [genesisCoin],
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
    final launcherCoin =  await fullNodeSimulator.getCoinById(launcherCoinPrototype.id);

    // print(launcherCoin);
    final launcherCoinSpend =  await fullNodeSimulator.getCoinSpend(launcherCoin!);
    print(launcherCoinSpend!.solution);

    // print(launcherCoinSpend!.additions);
    final singletonCoinPrototype = launcherCoinSpend!.additions[0];
final singletonCoin =  await fullNodeSimulator.getCoinById(singletonCoinPrototype.id);
// print(singletonCoin);
    // print(genesisCoinSpend)
    final extraData = launcherCoinSpend.solution.rest().rest().first();
    // final poolStateCons = poolStateBytes.first();
    // print(String.fromCharCode(poolStateCons.first().toInt()));
    final poolState = PoolState.fromExtraData(extraData);
    print(poolState);
  });
}
