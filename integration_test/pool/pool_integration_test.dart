import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/pool_state.dart';
import 'package:chia_utils/src/pool/service/wallet.dart';
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

  test('should create plot nft', () async{
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
      coins: nathan.standardCoins,
      p2SingletonDelayedPuzzlehash: nathan.firstPuzzlehash,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

     await fullNodeSimulator.pushTransaction(plotNftSpendBundle);
      await fullNodeSimulator.moveToNextBlock();
  });
}
