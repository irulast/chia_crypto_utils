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
  final walletGenerationStartTime = DateTime.now().millisecondsSinceEpoch;
  final nathan = ChiaEnthusiast(fullNodeSimulator, derivations: 300);
  await nathan.farmCoins();
  await nathan.issueMultiIssuanceCat();

  final startingCoin = nathan.catCoins.first;

  const desiredNumberOfCoins = 200;

  const desiredAmountPerCoin = 1000;

  const feePerSpentCoin = 1000;

  final numberOfSplits = (log(desiredNumberOfCoins) / log(2)).ceil();

  final numberOfOutputCoins = pow(2, numberOfSplits);

  final calculatedTotalFee = calculateTotalFee(feePerSpentCoin, numberOfSplits);

  if (startingCoin.amount < desiredNumberOfCoins * desiredAmountPerCoin + calculatedTotalFee) {
    throw ArgumentError('coin value is not enough to cover desired output coins and fee');
  }

  final startTime = DateTime.now().millisecondsSinceEpoch;
  final walletGenerationDuration = (startTime - walletGenerationStartTime) / 1000;

  print('time to generate wallet: $walletGenerationDuration');
  final airdropId = startingCoin.id.sha256Hash();

  for (var i = 0; i < numberOfSplits; i++) {
    final isLastSplit = i == numberOfSplits - 1;

    var derivationIndex = 0;
    final payments = <Payment>{};
    if (isLastSplit) {
      while (payments.length < desiredNumberOfCoins) {
        payments.add(
          Payment(
            desiredAmountPerCoin,
            nathan.puzzlehashes[derivationIndex],
            memos: <Bytes>[airdropId],
          ),
        );
        derivationIndex++;
      }
    }
    for (final coin in nathan.catCoins) {
      final childCoinOneAmount = coin.amount ~/ 2;
      final childCoinTwoAmount = coin.amount - childCoinOneAmount;

      payments.add(
        Payment(
          childCoinOneAmount,
          nathan.puzzlehashes[derivationIndex],
          memos: <Bytes>[airdropId],
        ),
      );
      derivationIndex++;

      payments.add(
        Payment(
          childCoinTwoAmount,
          nathan.puzzlehashes[derivationIndex],
          memos: <Bytes>[airdropId],
        ),
      );
      derivationIndex++;
    }

    final spendBundle = catWalletService.createSpendBundle(
      payments: payments.toList(),
      catCoinsInput: nathan.catCoins,
      keychain: nathan.keychain,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    await nathan.refreshCoins();

    print('${((i + 1) / numberOfSplits) * 100}% done');
  }
  final endTime = DateTime.now().millisecondsSinceEpoch;
  final duration = (endTime - startTime) / 1000;

  print('total duration: $duration seconds');
  print('calculated total fee: $calculatedTotalFee');
}

int calculateTotalFee(int feePerSpentCoin, int numberOfSplits) {
  var totalFee = 0;
  for (var i = 1; i < numberOfSplits + 1; i++) {
    final coinsCreatedInSplit = pow(2, i);
    totalFee += coinsCreatedInSplit.toInt() * feePerSpentCoin;
  }
  return totalFee;
}
