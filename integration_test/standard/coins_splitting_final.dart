import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async {
  // if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
  //   print(SimulatorUtils.simulatorNotRunningWarning);
  //   return;
  // }

  // final simulatorHttpRpc = SimulatorHttpRpc(
  //   SimulatorUtils.simulatorUrl,
  //   certBytes: SimulatorUtils.certBytes,
  //   keyBytes: SimulatorUtils.keyBytes,
  // );

  // final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  // // set up context, services
  // ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  // final catWalletService = CatWalletService();

  // final nathan = ChiaEnthusiast(fullNodeSimulator, derivations: 6);
  // await nathan.farmCoins();
  // await nathan.issueMultiIssuanceCat();

  // final startingCoin = nathan.catCoins..first;
  const desiredAmountPerCoin = 100;

  const desiredNumberOfCoins = 410000;
  // get at most first two digits of desiredNumberOfCoins
  



  // final numberOfSplits = (log(desiredMinimumNumberOfCoins / startingNumberOfCoins) / log(2)).ceil();
  // print(numberOfSplits);
  // print(pow(2, numberOfSplits));

  // final startTime = DateTime.now().millisecondsSinceEpoch;
  // for (var i = 0; i < numberOfSplits; i++) {
  //   final numberOfCoinsToCreate = nathan.catCoins.length * 2;
  //   final fee = numberOfCoinsToCreate * 1000;
  //   print('fee: $fee');
  //   print('number of coins created in split: $numberOfCoinsToCreate');
  //   final pushTransactionFutures = <Future>[];
  //   for (final coin in nathan.catCoins) {
  //     final feePerCoin = (fee / nathan.catCoins.length).ceil();
  //     final amountMinusFee = coin.amount - feePerCoin;

  //     final coinAmount = amountMinusFee ~/ 2;

  //     final spendBundle = catWalletService.createSpendBundle(
  //       payments: [
  //         Payment(coinAmount, nathan.puzzlehashes[0]),
  //         Payment(coinAmount, nathan.puzzlehashes[1])
  //       ],
  //       catCoinsInput: [coin],
  //       changePuzzlehash: Program.fromBool(true).hash(),
  //       keychain: nathan.keychain,
  //     );
  //     catWalletService.validateSpendBundle(spendBundle);
  //     pushTransactionFutures.add(fullNodeSimulator.pushTransaction(spendBundle));
  //   }

  //   await Future.wait<void>(pushTransactionFutures);
  //   await fullNodeSimulator.moveToNextBlock();

  //   await nathan.refreshCoins();

  //   print('${(i / numberOfSplits) * 100}% done');
  // }
  // final endTime = DateTime.now().millisecondsSinceEpoch;
  // final duration = (endTime - startTime) / 1000;

  // print('total duration: $duration seconds');
}

extension ShortenIntToTwoDigits on int {
  int toNDigits(int nDigits) {
    final asString = toString();
    final currentNumberOfDigits = asString.length;
    if (currentNumberOfDigits > nDigits) {
      return int.parse(asString.substring(0, nDigits));
    }
    if (currentNumberOfDigits < nDigits) {
      final newString = StringBuffer(asString);
      while (newString.length < nDigits) {
        newString.write('0');
      }
      return int.parse(newString.toString());
    }
    return this;
  }

  int get numberOfDigits => toString().length;
}
