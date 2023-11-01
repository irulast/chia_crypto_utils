import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class StandardCoinSplittingService {
  final standardWalletService = StandardWalletService();
  SpendBundle createCoinSplittingSpendBundle({
    required CoinPrototype coin,
    required int targetCoinCount,
    required int targetAmountPerCoin,
    required int feePerCoinSpend,
    required int splitWidth,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzleHash,
  }) {
    if (splitWidth > targetCoinCount) {
      throw InvalidCoinSplittingParametersException(
        'Split with is greater than desired number of coins',
      );
    }
    if (keychain.puzzlehashes.length < splitWidth + 2) {
      throw InvalidCoinSplittingParametersException(
        'Need a keychain with size >= splitWidth + 2',
      );
    }
    final changePh = changePuzzleHash ?? keychain.puzzlehashes.first;
    final splitPuzzlehashes = keychain.puzzlehashes.where((ph) => ph != changePh).toList();

    var totalCoinsCreated = 0;

    final initialSplitPayments = splitPuzzlehashes
        .sublist(0, splitWidth)
        .map((p) => Payment(targetAmountPerCoin, p, memos: <Bytes>[p]))
        .toList();

    final numberOfCoinSpends = (targetCoinCount / splitWidth).ceil();

    final coinsLeftToCreateAfterInitialSplit = targetCoinCount - splitWidth;

    final surplus = coinsLeftToCreateAfterInitialSplit * targetAmountPerCoin;
    print('split 1');
    final initialSplitSpendBundle = standardWalletService.createSpendBundle(
      payments: initialSplitPayments,
      coinsInput: [coin],
      originId: coin.id,
      keychain: keychain,
      surplus: surplus,
      fee: feePerCoinSpend * numberOfCoinSpends,
      changePuzzlehash: changePh,
    );

    totalCoinsCreated += splitWidth;
    var totalSpendBundle = initialSplitSpendBundle;

    // need to make sure we don't spend changeback coin so we use up all of the surplus value from the initial split spend bundle
    var previousSplitNetAdditions =
        initialSplitSpendBundle.netAdditions.where((element) => element.puzzlehash != changePh);

    var splitCount = 1;
    while (totalCoinsCreated < targetCoinCount) {
      splitCount++;
      print('split $splitCount');
      final splitNetAdditions = <CoinPrototype>[];
      for (final previousSplitAddition in previousSplitNetAdditions) {
        if (previousSplitAddition.amount != targetAmountPerCoin) {
          print(previousSplitAddition);
        }
        final numberOfCoinsToCreate = min(splitWidth, targetCoinCount - totalCoinsCreated);
        if (numberOfCoinsToCreate == 0) {
          break;
        }

        final payments = splitPuzzlehashes
            // +1 to make up for spent coin
            .sublist(0, numberOfCoinsToCreate + 1)
            .map((p) => Payment(targetAmountPerCoin, p, memos: <Bytes>[p]))
            .toList();

        final spendBundle = standardWalletService.createSpendBundle(
          payments: payments,
          coinsInput: [previousSplitAddition],
          originId: previousSplitAddition.id,
          keychain: keychain,
          changePuzzlehash: changePh,
        );

        totalSpendBundle += spendBundle;
        splitNetAdditions.addAll(
          spendBundle.netAdditions.where((element) => element.puzzlehash != changePh),
        );

        totalCoinsCreated += numberOfCoinsToCreate;
      }

      previousSplitNetAdditions = splitNetAdditions;
    }

    return totalSpendBundle;
  }
}

class InvalidCoinSplittingParametersException implements Exception {
  InvalidCoinSplittingParametersException([this.message]);

  final String? message;

  @override
  String toString() {
    return 'Invalid Coin splitting parameters${(message != null) ? ': $message' : ''}';
  }
}
