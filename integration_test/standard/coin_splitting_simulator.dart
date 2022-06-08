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

  Future<void> createAndPushSplittingTransactions({
    required List<CatCoin> catCoins,
    required List<Coin> standardCoinsForFee,
    required WalletKeychain keychain,
    required int splitWidth,
    required int feePerCoin,
  }) async {
    final transactionFutures = <Future>[];
    final additionIdsToLookFor = <Bytes>[];
    for (final catCoin in catCoins) {
      final payments = <Payment>[];
      for (var i = 0; i < splitWidth - 1; i++) {
        payments.add(Payment(catCoin.amount ~/ splitWidth, keychain.puzzlehashes[i]));
      }
      final lastPaymentAmount = catCoin.amount -
          payments.fold(0, (previousValue, payment) => previousValue + payment.amount);
      payments.add(Payment(lastPaymentAmount.toInt(), keychain.puzzlehashes[splitWidth - 1]));
      if (payments.toSet().length != payments.length) {
        print(payments.map((e) => e.puzzlehash).toList());
        throw Exception('duplicate output');
      }
      final spendBundle = CatWalletService().createSpendBundle(
        payments: payments,
        catCoinsInput: [catCoin],
        keychain: keychain,
        standardCoinsForFee: standardCoinsForFee,
        fee: splitWidth * feePerCoin,
      );
      additionIdsToLookFor.add(spendBundle.additions.first.id);
      transactionFutures.add(fullNodeSimulator.pushTransaction(spendBundle));
    }
    await Future.wait<void>(transactionFutures);

    // wait for all spend bundles to be pushed
    while ((await fullNodeSimulator.getCoinsByIds(additionIdsToLookFor)).length ==
        additionIdsToLookFor.length) {
      await Future<void>.delayed(const Duration(seconds: 19));
      print('waiting for transactions to be included...');
    }
  }

  int calculateNumberOfNWidthSplitsRequired({
    required int desiredNumberOfCoins,
    required int initialSplitWidth,
  }) {
    late int numberOfBinarySplits;
    num smallestDifference = 1000000;

    for (var i = 0; i < 10; i++) {
      final resultingCoins = pow(initialSplitWidth, i).toInt();

      if (resultingCoins > desiredNumberOfCoins) {
        break;
      }

      if (resultingCoins == 9) {
        print(9);
      }

      final desiredNumberOfCoinsDigitsToCompare = desiredNumberOfCoins.toNDigits(3);

      final resultingCoinsDigitsToCompare = resultingCoins.toNDigits(3);

      var difference = desiredNumberOfCoinsDigitsToCompare - resultingCoinsDigitsToCompare;
      if (difference < 0 && resultingCoins.numberOfDigits > 1) {
        final resultingCoinsDigitsMinusOneToCompare =
            resultingCoins.toNDigits(resultingCoins.numberOfDigits - 1);

        difference = desiredNumberOfCoinsDigitsToCompare - resultingCoinsDigitsMinusOneToCompare;
      }

      if (difference >= 0 && difference < smallestDifference) {
        smallestDifference = difference;
        numberOfBinarySplits = i;
      }
    }

    return numberOfBinarySplits;
  }

  // set up context, services
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  // final catWalletService = CatWalletService();

  final nathan = ChiaEnthusiast(fullNodeSimulator, derivations: 11);
  await nathan.farmCoins();
  await nathan.issueMultiIssuanceCat();

  // final startingCoin = nathan.catCoins..first;
  const desiredAmountPerCoin = 100;

  const desiredNumberOfCoins = 310;
  // get at most first two digits of desiredNumberOfCoins
  // final desiredNumberOfCoinsDigitsToCompare = (desiredNumberOfCoins.numberOfDigits > 2)
  //     ? desiredNumberOfCoins.toNDigits(2)
  //     : desiredNumberOfCoins;

  // calculate number of binary splits

  const desiredSplitWidth = 3;

  final numberOfBinarySplits = calculateNumberOfNWidthSplitsRequired(
    desiredNumberOfCoins: desiredNumberOfCoins,
    initialSplitWidth: desiredSplitWidth,
  );

  final resultingCoinsFromBinarySplits = pow(desiredSplitWidth, numberOfBinarySplits);

  var numberOfDecaSplits = 0;
  while (resultingCoinsFromBinarySplits * pow(10, numberOfDecaSplits) <= desiredNumberOfCoins) {
    numberOfDecaSplits++;
  }
  numberOfDecaSplits--;
  // want to optimize amount per coin
  final totalNumberOfResultingCoins = resultingCoinsFromBinarySplits * pow(10, numberOfDecaSplits);

  print('number of $desiredSplitWidth splits: $numberOfBinarySplits');
  print('number of ten splits: $numberOfDecaSplits');
  print(' ');

  print('----------');
  print(' ');
  print('total number of resulting coins: $totalNumberOfResultingCoins');
  print('desired coins: $desiredNumberOfCoins');

  for (var i = 0; i < numberOfBinarySplits; i++) {
    await createAndPushSplittingTransactions(
      catCoins: nathan.catCoins,
      standardCoinsForFee: nathan.standardCoins,
      keychain: nathan.keychain,
      splitWidth: 2,
      feePerCoin: 100,
    );
    await fullNodeSimulator.moveToNextBlock();

    await nathan.refreshCoins();
    print('finished 2 split');
  }

  for (var i = 0; i < numberOfDecaSplits; i++) {
    await createAndPushSplittingTransactions(
      catCoins: nathan.catCoins,
      standardCoinsForFee: nathan.standardCoins,
      keychain: nathan.keychain,
      splitWidth: 10,
      feePerCoin: 100,
    );
    await fullNodeSimulator.moveToNextBlock();

    await nathan.refreshCoins();
    print('finished 10 split');
  }

  Future<void> createAndPushFinalSplittingTransactions({
    required List<CatCoin> catCoins,
    required List<Coin> standardCoinsForFee,
    required WalletKeychain keychain,
    required int splitWidth,
    required int feePerCoin,
    required int desiredNumberOfCoins,
    required int desiredAmountPerCoin,
    required Puzzlehash changePuzzlehash,
  }) async {
    var numberOfCoinsCreated = 0;
    final transactionFutures = <Future>[];
    var isFinished = false;
    for (final catCoin in catCoins) {
      final payments = <Payment>[];
      for (var i = 0; i < 10; i++) {
        if (numberOfCoinsCreated >= desiredNumberOfCoins) {
          isFinished = true;
          break;
        }
        payments.add(Payment(desiredAmountPerCoin, keychain.puzzlehashes[i]));
        numberOfCoinsCreated++;
      }

      final lastPaymentAmount = catCoin.amount -
          payments.fold(0, (previousValue, payment) => previousValue + payment.amount);
      payments.add(Payment(lastPaymentAmount.toInt(), changePuzzlehash));

      final spendBundle = CatWalletService().createSpendBundle(
        payments: payments,
        catCoinsInput: [catCoin],
        keychain: nathan.keychain,
      );
      transactionFutures.add(fullNodeSimulator.pushTransaction(spendBundle));
      if (isFinished) {
        break;
      }
    }
    await Future.wait<void>(transactionFutures);
  }

  // // final split

  await fullNodeSimulator.moveToNextBlock();
  await nathan.refreshCoins();
  print(nathan.catCoins.where((c) => c.amount == desiredAmountPerCoin).length);

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

extension ShortenIntToTwoDigits on num {
  num toNDigits(int nDigits) {
    final base10Upper = pow(10, nDigits);
    final base10Lower = pow(10, nDigits - 1);
    if (this > base10Upper) {
      var reduced = this;
      while (reduced > base10Upper) {
        reduced /= 10;
      }
      return reduced;
    }
    if (this < base10Lower) {
      var increased = this;
      while (increased < base10Lower) {
        increased *= 10;
      }
      return increased;
    }
    return this;
  }

  int get numberOfDigits => toString().replaceAll('.', '').length;
}
