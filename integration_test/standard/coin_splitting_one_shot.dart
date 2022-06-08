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

  const feePerCreatedCoin = 1000;

  const totalFee = feePerCreatedCoin * desiredNumberOfCoins;

  print(startingCoin.amount);
  const totalCost = (desiredNumberOfCoins * desiredAmountPerCoin) + totalFee;
  print(totalCost);

  if (startingCoin.amount < totalCost) {
    throw ArgumentError('coin value is not enough to cover desired output coins and fee');
  }

  final startTime = DateTime.now().millisecondsSinceEpoch;
  final walletGenerationDuration = (startTime - walletGenerationStartTime) / 1000;

  print('time to generate wallet: $walletGenerationDuration');
  final airdropId = startingCoin.id.sha256Hash();

  final payments = <Payment>{};
  var derivationIndex = 0;
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

  final spendBundle = catWalletService.createSpendBundle(
    payments: payments.toList(),
    catCoinsInput: [startingCoin],
    standardCoinsForFee: nathan.standardCoins,
    keychain: nathan.keychain,
    changePuzzlehash: nathan.firstPuzzlehash,
    fee: totalFee,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final endTime = DateTime.now().millisecondsSinceEpoch;
  final duration = (endTime - startTime) / 1000;

  print('total duration: $duration seconds');
  final totalCoins =  await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(nathan.outerPuzzlehashes);
  print(totalCoins.length);
}

int calculateTotalFee(int feePerSpentCoin, int numberOfSplits) {
  var totalFee = 0;
  for (var i = 1; i < numberOfSplits + 1; i++) {
    final coinsCreatedInSplit = pow(2, i);
    totalFee += coinsCreatedInSplit.toInt() * feePerSpentCoin;
  }
  return totalFee;
}
