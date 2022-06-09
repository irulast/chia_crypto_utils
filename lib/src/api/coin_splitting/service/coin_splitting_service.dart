import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CoinSplittingService {
  CoinSplittingService(this.fullNode);
  CoinSplittingService.fromContext() : fullNode = ChiaFullNodeInterface.fromContext();
  final ChiaFullNodeInterface fullNode;
  final catWalletService = CatWalletService();
  final standardWalletService = StandardWalletService();

  Future<void> splitCoins({
    required CatCoin catCoinToSplit,
    required List<Coin> standardCoinsForFee,
    required WalletKeychain keychain,
    required int splitWidth,
    required int feePerCoin,
    required int desiredNumberOfCoins,
    required int desiredAmountPerCoin,
    required Puzzlehash changePuzzlehash,
  }) async {
    final numberOfNWidthSplits = calculateNumberOfNWidthSplitsRequired(
      desiredNumberOfCoins: desiredNumberOfCoins,
      initialSplitWidth: splitWidth,
    );

    print('number of $splitWidth width splits: $numberOfNWidthSplits');

    final resultingCoinsFromNWidthSplits = pow(splitWidth, numberOfNWidthSplits).toInt();
    final numberOfDecaSplits =
        calculateNumberOfDecaSplitsRequired(resultingCoinsFromNWidthSplits, desiredNumberOfCoins);

    print('number of 10 width splits: $numberOfDecaSplits');

    final totalNumberOfResultingCoins =
        resultingCoinsFromNWidthSplits * pow(10, numberOfDecaSplits);

    print('total number of resulting coins: $totalNumberOfResultingCoins');

    validateInputs(
      feePerCoin: feePerCoin,
      numberOfDecaSplits: numberOfDecaSplits,
      numberOfNWidthSplits: numberOfNWidthSplits,
      splitWidth: splitWidth,
      desiredCoinAmount: desiredAmountPerCoin,
      startingCatAmount: catCoinToSplit.amount,
      startingStandardCoins: standardCoinsForFee,
    );

    final airdropId = catCoinToSplit.id;
    final airdropFeeCoinsId = standardCoinsForFee.joinedIds.sha256Hash();

    var standardCoins = standardCoinsForFee;

    if (standardCoinsForFee.length > 1) {
      await createAndPushStandardCoinJoinTransaction(
        coins: standardCoinsForFee,
        keychain: keychain,
        destinationPuzzlehash: keychain.puzzlehashes.first,
        airdropFeeCoinsId: airdropFeeCoinsId,
      );

      standardCoins = await fullNode.getCoinsByMemo(airdropFeeCoinsId);
      print('joined standard coins for fee');

      if (standardCoins.length != 1) {
        throw Exception('should only be one standard coin after join. got ${standardCoins.length}');
      }
    }

    var catCoins = [catCoinToSplit];

    for (var i = 0; i < numberOfNWidthSplits; i++) {
      final catParentCoinIds = catCoins.map((cc) => cc.id).toSet();
      final standardParentCoinIds = standardCoins.map((c) => c.id).toSet();

      final earliestSpentBlockIndex = await createAndPushSplittingTransactions(
        catCoins: catCoins,
        standardCoinsForFee: standardCoins,
        keychain: keychain,
        splitWidth: splitWidth,
        feePerCoin: feePerCoin,
        airdropId: airdropId,
        airdropFeeCoinsId: airdropFeeCoinsId,
      );
      catCoins = (await fullNode.getCatCoinsByOuterPuzzleHashes(
        keychain.getOuterPuzzleHashesForAssetId(catCoinToSplit.assetId).sublist(0, splitWidth),
        startHeight: earliestSpentBlockIndex,
      ))
          .where((cc) => catParentCoinIds.contains(cc.parentCoinInfo))
          .toList();

      standardCoins = (await fullNode.getCoinsByPuzzleHashes(
        keychain.puzzlehashes.sublist(0, splitWidth),
        startHeight: earliestSpentBlockIndex,
      ))
          .where((c) => standardParentCoinIds.contains(c.parentCoinInfo))
          .toList();
      print('finished $splitWidth width split');
    }

    for (var i = 0; i < numberOfDecaSplits; i++) {
      final catParentCoinIds = catCoins.map((cc) => cc.id).toSet();
      final standardParentCoinIds = standardCoins.map((c) => c.id).toSet();

      final earliestSpentBlockIndex = await createAndPushSplittingTransactions(
        catCoins: catCoins,
        standardCoinsForFee: standardCoins,
        keychain: keychain,
        splitWidth: 10,
        feePerCoin: feePerCoin,
        airdropId: airdropId,
        airdropFeeCoinsId: airdropFeeCoinsId,
      );
      catCoins = (await fullNode.getCatCoinsByOuterPuzzleHashes(
        keychain.getOuterPuzzleHashesForAssetId(catCoinToSplit.assetId).sublist(0, 10),
        startHeight: earliestSpentBlockIndex,
      ))
          .where((cc) => catParentCoinIds.contains(cc.parentCoinInfo))
          .toList();

      standardCoins = (await fullNode.getCoinsByPuzzleHashes(
        keychain.puzzlehashes.sublist(0, 10),
        startHeight: earliestSpentBlockIndex,
      ))
          .where((c) => standardParentCoinIds.contains(c.parentCoinInfo))
          .toList();
      print('finished 10 width split');
    }

    await createAndPushFinalSplittingTransactions(
      catCoins: catCoins,
      standardCoinsForFee: standardCoins,
      keychain: keychain,
      feePerCoin: feePerCoin,
      airdropId: airdropId,
      desiredAmountPerCoin: desiredAmountPerCoin,
      desiredNumberOfCoins: desiredNumberOfCoins,
      changePuzzlehash: keychain.puzzlehashes.first,
    );
    print('finish splitting with airdropId: $airdropId');
  }

  Future<int> createAndPushFinalSplittingTransactions({
    required List<CatCoin> catCoins,
    required List<Coin> standardCoinsForFee,
    required WalletKeychain keychain,
    required int feePerCoin,
    required int desiredNumberOfCoins,
    required int desiredAmountPerCoin,
    required Puzzlehash changePuzzlehash,
    required Bytes airdropId,
  }) async {
    if (standardCoinsForFee.length != catCoins.length) {
      throw ArgumentError('Should provide a standard coin for  every cat coin');
    }
    var numberOfCoinsCreated = 0;
    final parentIdsToLookFor = <Bytes>[];

    final transactionFutures = <Future>[];
    var isFinished = false;

    for (var coinIndex = 0; coinIndex < catCoins.length; coinIndex++) {
      final catCoin = catCoins[coinIndex];
      final standardCoin = standardCoinsForFee[coinIndex];

      final payments = <Payment>[];
      for (var i = 0; i < 10; i++) {
        if (numberOfCoinsCreated >= desiredNumberOfCoins) {
          isFinished = true;
          break;
        }
        payments.add(
          Payment(
            desiredAmountPerCoin,
            keychain.puzzlehashes[i],
            memos: <Bytes>[keychain.puzzlehashes[i]],
          ),
        );
        numberOfCoinsCreated++;
      }

      final lastPaymentAmount = catCoin.amount - payments.totalValue;
      payments.add(Payment(lastPaymentAmount, changePuzzlehash));

      final spendBundle = catWalletService.createSpendBundle(
        payments: payments,
        catCoinsInput: [catCoin],
        keychain: keychain,
        standardCoinsForFee: [standardCoin],
        changePuzzlehash: changePuzzlehash,
        fee: 10 * feePerCoin,
      );
      parentIdsToLookFor.add(catCoin.id);

      transactionFutures.add(fullNode.pushTransaction(spendBundle));
      if (isFinished) {
        break;
      }
    }
    await Future.wait<void>(transactionFutures);
    return waitForTransactions(parentIdsToLookFor);
  }

  Future<int> createAndPushSplittingTransactions({
    required List<CatCoin> catCoins,
    required List<Coin> standardCoinsForFee,
    required WalletKeychain keychain,
    required int splitWidth,
    required int feePerCoin,
    required Bytes airdropId,
    required Bytes airdropFeeCoinsId,
  }) async {
    if (standardCoinsForFee.length != catCoins.length) {
      throw ArgumentError('Should provide a standard coin for  every cat coin');
    }
    final transactionFutures = <Future>[];
    final parentIdsToLookFor = <Bytes>[];
    for (var coinIndex = 0; coinIndex < catCoins.length; coinIndex++) {
      final catCoin = catCoins[coinIndex];
      final standardCoin = standardCoinsForFee[coinIndex];

      final payments = <Payment>[];
      for (var i = 0; i < splitWidth - 1; i++) {
        payments.add(
          Payment(
            catCoin.amount ~/ splitWidth,
            keychain.puzzlehashes[i],
            memos: <Bytes>[airdropId],
          ),
        );
      }

      final lastPaymentAmount = catCoin.amount - payments.totalValue;
      payments.add(
        Payment(
          lastPaymentAmount,
          keychain.puzzlehashes[splitWidth - 1],
          memos: <Bytes>[airdropId],
        ),
      );

      final totalFeeAmount = splitWidth * feePerCoin * 2; // fee coin and cat coin
      final standardCoinValueMinusFee = standardCoin.amount - totalFeeAmount;

      final standardPayments = <Payment>[];
      for (var i = 0; i < splitWidth - 1; i++) {
        standardPayments.add(
          Payment(
            standardCoinValueMinusFee ~/ splitWidth,
            keychain.puzzlehashes[i],
            memos: <Bytes>[airdropFeeCoinsId],
          ),
        );
      }
      final lastStandardPaymentAmount = standardCoinValueMinusFee - standardPayments.totalValue;
      standardPayments.add(
        Payment(
          lastStandardPaymentAmount,
          keychain.puzzlehashes[splitWidth - 1],
          memos: <Bytes>[airdropFeeCoinsId],
        ),
      );

      final standardSpendBundle = standardWalletService.createSpendBundle(
        payments: standardPayments,
        coinsInput: [standardCoin],
        keychain: keychain,
        fee: totalFeeAmount,
      );

      final spendBundle = CatWalletService().createSpendBundle(
        payments: payments,
        catCoinsInput: [catCoin],
        keychain: keychain,
      );
      parentIdsToLookFor.add(catCoin.id);
      transactionFutures.add(fullNode.pushTransaction(spendBundle + standardSpendBundle));
    }
    await Future.wait<void>(transactionFutures);

    // wait for all spend bundles to be pushed
    return waitForTransactions(parentIdsToLookFor);
  }

  Future<int> waitForTransactions(List<Bytes> parentCoinIds) async {
    final unspentIds = Set<Bytes>.from(parentCoinIds);

    int? firstSpentBlockIndex;

    while (unspentIds.isNotEmpty) {
      print('waiting for transactions to be included...');

      final coins = await fullNode.getCoinsByIds(unspentIds.toList(), includeSpentCoins: true);

      final spentCoins = coins.where((coin) => coin.isSpent);

      if (spentCoins.isNotEmpty && firstSpentBlockIndex == null) {
        final spentBlockIndices = spentCoins.map((c) => c.spentBlockIndex);
        firstSpentBlockIndex = spentBlockIndices.reduce(min);
      }

      final spentIds = spentCoins.map((c) => c.id).toSet();
      unspentIds.removeWhere(spentIds.contains);

      await Future<void>.delayed(const Duration(seconds: 19));
    }
    return firstSpentBlockIndex!;
  }

  int calculateNumberOfNWidthSplitsRequired({
    required int desiredNumberOfCoins,
    required int initialSplitWidth,
  }) {
    late int numberOfNWidthSplits;
    num smallestDifference = 10000000;

    final maxResultingCoinDigits = pow(initialSplitWidth, 10).toInt();

    for (var i = 0; i < 10; i++) {
      final resultingCoins = pow(initialSplitWidth, i).toInt();

      if (resultingCoins > desiredNumberOfCoins) {
        break;
      }

      final desiredNumberOfCoinsDigitsToCompare =
          desiredNumberOfCoins.toNDigits(maxResultingCoinDigits);
      final resultingCoinsDigitsToCompare = resultingCoins.toNDigits(maxResultingCoinDigits);

      var difference = desiredNumberOfCoinsDigitsToCompare - resultingCoinsDigitsToCompare;
      if (difference < 0) {
        final resultingCoinsDigitsMinusOneToCompare =
            resultingCoins.toNDigits(maxResultingCoinDigits - 1);

        difference = desiredNumberOfCoinsDigitsToCompare - resultingCoinsDigitsMinusOneToCompare;
      }

      if (difference < smallestDifference) {
        smallestDifference = difference;
        numberOfNWidthSplits = i;
      }
    }

    return numberOfNWidthSplits;
  }

  Future<int> createAndPushStandardCoinJoinTransaction({
    required List<Coin> coins,
    required WalletKeychain keychain,
    required Puzzlehash destinationPuzzlehash,
    int fee = 0,
    Bytes? airdropFeeCoinsId,
  }) async {
    final totalAmountMinusFee = coins.totalValue - fee;
    final joinSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          totalAmountMinusFee,
          destinationPuzzlehash,
          memos: (airdropFeeCoinsId == null) ? null : <Bytes>[airdropFeeCoinsId],
        )
      ],
      coinsInput: coins,
      keychain: keychain,
      fee: fee,
    );

    await fullNode.pushTransaction(joinSpendBundle);
    return waitForTransactions([coins.first.id]);
  }

  int calculateNumberOfDecaSplitsRequired(
    int resultingCoinsFromNWidthSplits,
    int desiredNumberOfCoins,
  ) {
    var numberOfDecaSplits = 0;
    while (resultingCoinsFromNWidthSplits * pow(10, numberOfDecaSplits) <= desiredNumberOfCoins) {
      numberOfDecaSplits++;
    }
    // want just under desired amount
    return numberOfDecaSplits - 1;
  }

  void validateInputs({
    required int feePerCoin,
    required int numberOfDecaSplits,
    required int numberOfNWidthSplits,
    required int splitWidth,
    required int desiredCoinAmount,
    required int startingCatAmount,
    required List<Coin> startingStandardCoins,
  }) {
    // check that final cat amount is enough to cover desired amount
    var catCoinAmount = startingCatAmount;

    for (var i = 0; i < numberOfNWidthSplits; i++) {
      catCoinAmount = catCoinAmount ~/ splitWidth;
    }

    for (var i = 0; i < numberOfDecaSplits; i++) {
      catCoinAmount = catCoinAmount ~/ 10;
    }

    if (desiredCoinAmount > catCoinAmount) {
      throw ArgumentError('Cat balance is not enough to meet desired splitting parameters');
    }

    // check that fee coins don't get too small

    var feeCoinAmount = startingStandardCoins.totalValue;
    if (startingStandardCoins.length > 1) {
      // account for initial join if necessary
      feeCoinAmount -= startingStandardCoins.length * feePerCoin;
    }

    final totalFeePerNWidthSplit = splitWidth * feePerCoin * 2;
    for (var i = 0; i < numberOfNWidthSplits; i++) {
      feeCoinAmount = (feeCoinAmount - totalFeePerNWidthSplit) ~/ splitWidth;
    }

    final totalFeePerDecaSplit = 10 * feePerCoin * 2;
    for (var i = 0; i < numberOfDecaSplits; i++) {
      feeCoinAmount = (feeCoinAmount - totalFeePerDecaSplit) ~/ splitWidth;
    }

    if (feePerCoin > feeCoinAmount) {
      throw ArgumentError('Standard balance is not enough to meet desired splitting parameters');
    }
  }

  int calculateTotalFee({
    required int feePerCoin,
    required int numberOfDecaSplits,
    required int numberOfNWidthSplits,
    required int splitWidth,
    required int desiredNumberOfCoins,
  }) {
    var totalFee = 0;
    for (var i = 1; i < numberOfDecaSplits + 1; i++) {
      final coinsCreatedInSplit = pow(10, i);
      totalFee += coinsCreatedInSplit.toInt() * feePerCoin;
    }

    for (var i = 1; i < numberOfNWidthSplits + 1; i++) {
      final coinsCreatedInSplit = pow(splitWidth, i);
      totalFee += coinsCreatedInSplit.toInt() * feePerCoin;
    }
    //account for parallel standard coin splitting as well
    totalFee *= 2;

    // last split
    totalFee += desiredNumberOfCoins * feePerCoin;
    return totalFee;
  }
}

extension DigitOperations on num {
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
