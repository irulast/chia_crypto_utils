@Timeout(Duration(minutes: 5))

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
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

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final coinSplittingService = CoinSplittingService(
    fullNodeSimulator,
    coinSearchWaitPeriod: const Duration(seconds: 1),
  );

  fullNodeSimulator.run(blockPeriod: const Duration(seconds: 50));

  final meera = ChiaEnthusiast(fullNodeSimulator, derivations: 10);
  await meera.farmCoins();
  await meera.issueMultiIssuanceCat(meera.keychainSecret.masterPrivateKey);

  test('should split coins', () async {
    await coinSplittingService.splitCoins(
      catCoinToSplit: meera.catCoins[0],
      standardCoinsForFee: meera.standardCoins,
      keychain: meera.keychain,
      splitWidth: 3,
      feePerCoin: 10000,
      desiredNumberOfCoins: 91,
      desiredAmountPerCoin: 101,
      changePuzzlehash: meera.firstPuzzlehash,
    );

    final meeraAssetId = meera.catCoinMap.keys.first;

    final resultingCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(
      meera.keychain.getOuterPuzzleHashesForAssetId(meeraAssetId),
    );

    expect(resultingCoins.where((c) => c.amount == 101).length, equals(91));
  });

  test('should throw error when cat balance is not enough to meet desired splitting parameters ',
      () async {
    //cat coin balance is 100000000
    expect(
      () async {
        await coinSplittingService.splitCoins(
          catCoinToSplit: meera.catCoins[0],
          standardCoinsForFee: meera.standardCoins,
          keychain: meera.keychain,
          splitWidth: 3,
          feePerCoin: 1000,
          desiredNumberOfCoins: 91,
          desiredAmountPerCoin: 2000000,
          changePuzzlehash: meera.firstPuzzlehash,
        );
      },
      throwsArgumentError,
    );
  });

  test(
      'should throw error when standard balance is not enough to meet desired splitting parameters ',
      () async {
    //standard balance is 1999900000000
    expect(
      () async {
        await coinSplittingService.splitCoins(
          catCoinToSplit: meera.catCoins[0],
          standardCoinsForFee: meera.standardCoins,
          keychain: meera.keychain,
          splitWidth: 3,
          feePerCoin: 22000000000,
          desiredNumberOfCoins: 91,
          desiredAmountPerCoin: 101,
          changePuzzlehash: meera.firstPuzzlehash,
        );
      },
      throwsArgumentError,
    );
  });

  test('should throw error when there are not enough puzzlehashes to cover split width', () async {
    final nathan = ChiaEnthusiast(fullNodeSimulator, derivations: 2);
    await nathan.farmCoins();
    await nathan.issueMultiIssuanceCat(nathan.keychainSecret.masterPrivateKey);

    expect(
      () async {
        await coinSplittingService.splitCoins(
          catCoinToSplit: nathan.catCoins[0],
          standardCoinsForFee: nathan.standardCoins,
          keychain: nathan.keychain,
          splitWidth: 3,
          feePerCoin: 10000,
          desiredNumberOfCoins: 91,
          desiredAmountPerCoin: 101,
          changePuzzlehash: nathan.firstPuzzlehash,
        );
      },
      throwsArgumentError,
    );
  });
}