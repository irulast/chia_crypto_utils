import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async {
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
  final catWalletService = CatWalletService();

  final nathan = ChiaEnthusiast(fullNodeSimulator, derivations: 2);
  await nathan.farmCoins();
  await nathan.issueMultiIssuanceCat();

  final startingNumberOfCoins = nathan.catCoins.length;

  const desiredMinimumNumberOfCoins = 200;

  final numberOfSplits = (log(desiredMinimumNumberOfCoins / startingNumberOfCoins) / log(2)).ceil();
  print(numberOfSplits);
  print(pow(2, numberOfSplits));

  final startTime = DateTime.now().millisecondsSinceEpoch;

  for (var i = 0; i < numberOfSplits; i++) {
    final numberOfCoinsToCreate = nathan.catCoins.length * 2;
    final fee = numberOfCoinsToCreate * 1000;
    print('fee: $fee');
    print('number of coins created in split: $numberOfCoinsToCreate');
    var finalSpendBundle = SpendBundle.empty;
    for (final coin in nathan.catCoins) {
      final childCoinOneAmount = coin.amount ~/ 2;
      final childCoinTwoAmount = coin.amount - childCoinOneAmount;

      final spendBundle = catWalletService.createSpendBundle(
        payments: [
          Payment(childCoinOneAmount, nathan.firstPuzzlehash),
          Payment(childCoinTwoAmount, nathan.puzzlehashes[1])
        ],
        catCoinsInput: [coin],
        keychain: nathan.keychain,
      );

      finalSpendBundle += spendBundle;
    }

    await fullNodeSimulator.pushTransaction(finalSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    await nathan.refreshCoins();

    print('${(i / numberOfSplits) * 100}% done');
  }
  final endTime = DateTime.now().millisecondsSinceEpoch;
  final duration = (endTime - startTime) / 1000;

  print('total duration: $duration seconds');
}
