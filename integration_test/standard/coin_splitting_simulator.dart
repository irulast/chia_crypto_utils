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
  final desiredNumberOfCoinsDigitsToCompare = (desiredNumberOfCoins.numberOfDigits > 2)
      ? desiredNumberOfCoins.toNDigits(2)
      : desiredNumberOfCoins;

  // calculate number of binary splits
  late int numberOfBinarySplits;
  var smallestSurplus = 1000000;

  for (var i = 0; i < 10; i++) {
    final resultingCoins = pow(2, i).toInt();
    // if (resultingCoins > desiredNumberOfCoins) {
    //   break;
    // }
    late int resultingCoinsDigitsToCompare;
    if (resultingCoins > desiredNumberOfCoins) {
      resultingCoinsDigitsToCompare = resultingCoins;
    } else {
      resultingCoinsDigitsToCompare =
          resultingCoins.toNDigits(desiredNumberOfCoinsDigitsToCompare.numberOfDigits);
    }

    var surplus = resultingCoinsDigitsToCompare - desiredNumberOfCoinsDigitsToCompare;
    if (surplus < 0) {
      final resultingCoinsDigitsPlusOneToCompare =
          resultingCoins.toNDigits(resultingCoinsDigitsToCompare.numberOfDigits + 1);

      surplus = resultingCoinsDigitsPlusOneToCompare - desiredNumberOfCoinsDigitsToCompare;
    }

    if (surplus < smallestSurplus) {
      smallestSurplus = surplus;
      numberOfBinarySplits = i;
    }
  }

  final resultingCoinsFromBinarySplits = pow(2, numberOfBinarySplits);

  var numberOfDecaSplits = 0;
  while (resultingCoinsFromBinarySplits * pow(10, numberOfDecaSplits) < desiredNumberOfCoins) {
    numberOfDecaSplits++;
  }

  final totalNumberOfResultingCoins = resultingCoinsFromBinarySplits * pow(10, numberOfDecaSplits);

  print('number of binary splits: $numberOfBinarySplits');
  print('number of ten splits: $numberOfDecaSplits');
  print(' ');

  print('----------');
  print(' ');
  print('total number of resulting coins: $totalNumberOfResultingCoins');
  print('desired coins: $desiredNumberOfCoins');

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
