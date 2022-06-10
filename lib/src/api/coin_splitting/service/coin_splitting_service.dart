import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/utils/blockchain_utils.dart';

class CoinSplittingService {
  CoinSplittingService(this.fullNode) : blockchainUtils = BlockchainUtils(fullNode);
  CoinSplittingService.fromContext()
      : fullNode = ChiaFullNodeInterface.fromContext(),
        blockchainUtils = BlockchainUtils.fromContext();

  final ChiaFullNodeInterface fullNode;
  final BlockchainUtils blockchainUtils;
  final catWalletService = CatWalletService();
  final standardWalletService = StandardWalletService();
  final logger = LoggingContext().log;

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

    logger('number of $splitWidth width splits: $numberOfNWidthSplits');

    final resultingCoinsFromNWidthSplits = pow(splitWidth, numberOfNWidthSplits).toInt();
    final numberOfDecaSplits =
        calculateNumberOfDecaSplitsRequired(resultingCoinsFromNWidthSplits, desiredNumberOfCoins);

    logger('number of 10 width splits: $numberOfDecaSplits');

    final totalNumberOfResultingCoins =
        resultingCoinsFromNWidthSplits * pow(10, numberOfDecaSplits);

    logger('total number of resulting coins: $totalNumberOfResultingCoins');

    validateInputs(
      feePerCoin: feePerCoin,
      numberOfDecaSplits: numberOfDecaSplits,
      numberOfNWidthSplits: numberOfNWidthSplits,
      splitWidth: splitWidth,
      desiredCoinAmount: desiredAmountPerCoin,
      startingCatAmount: catCoinToSplit.amount,
      startingStandardCoins: standardCoinsForFee,
      puzzlehashes: keychain.puzzlehashes,
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
      logger('joined standard coins for fee');

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
      logger('finished $splitWidth width split');
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
      logger('finished 10 width split');
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
    logger('finish splitting with airdropId: $airdropId');
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

    return waitForTransactionsAndGetFirstSpentIndex(parentIdsToLookFor);
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

      final catPayments = makeSplittingPayments(
        coinAmount: catCoin.amount,
        splitWidth: splitWidth,
        puzzlehashes: keychain.puzzlehashes,
      );

      final catSpendBundle = catWalletService.createSpendBundle(
        payments: catPayments,
        catCoinsInput: [catCoin],
        keychain: keychain,
      );

      final totalFeeAmount = splitWidth * feePerCoin * 2; // fee coin and cat coin
      final standardCoinValueMinusFee = standardCoin.amount - totalFeeAmount;

      final standardPayments = makeSplittingPayments(
        coinAmount: standardCoinValueMinusFee,
        splitWidth: splitWidth,
        puzzlehashes: keychain.puzzlehashes,
      );

      final standardSpendBundle = standardWalletService.createSpendBundle(
        payments: standardPayments,
        coinsInput: [standardCoin],
        keychain: keychain,
        fee: totalFeeAmount,
      );

      parentIdsToLookFor.add(catCoin.id);
      transactionFutures.add(fullNode.pushTransaction(catSpendBundle + standardSpendBundle));
    }
    await Future.wait<void>(transactionFutures);

    // wait for all spend bundles to be pushed
    return waitForTransactionsAndGetFirstSpentIndex(parentIdsToLookFor);
  }

  List<Payment> makeSplittingPayments({
    required int coinAmount,
    required int splitWidth,
    required List<Puzzlehash> puzzlehashes,
  }) {
    final payments = <Payment>[];
    for (var i = 0; i < splitWidth - 1; i++) {
      payments.add(
        Payment(
          coinAmount ~/ splitWidth,
          puzzlehashes[i],
          memos: <Bytes>[puzzlehashes[i]],
        ),
      );
    }

    final lastPaymentAmount = coinAmount - payments.totalValue;
    final lastPuzzlehash = puzzlehashes[splitWidth - 1];
    payments.add(
      Payment(
        lastPaymentAmount,
        lastPuzzlehash,
        memos: <Bytes>[lastPuzzlehash],
      ),
    );
    return payments;
  }

  static int calculateNumberOfNWidthSplitsRequired({
    required int desiredNumberOfCoins,
    required int initialSplitWidth,
  }) {
    late int numberOfNWidthSplits;
    num smallestDifference = 1000000000;

    // adjust values to make sure maxResultingCoins doesn't go out of bounds
    var maxNWidthSplitIndex = 9;
    var maxResultingCoins = pow(initialSplitWidth, maxNWidthSplitIndex);
    // pow(...) returns negative went out of bounds
    while (maxResultingCoins <= 0) {
      maxNWidthSplitIndex--;
      maxResultingCoins = pow(initialSplitWidth, maxNWidthSplitIndex).powerOfTen;
    }

    final maxResultingCoinsPowerOfTen = maxResultingCoins.powerOfTen;

    for (var i = 0; i < maxNWidthSplitIndex + 1; i++) {
      final resultingCoins = pow(initialSplitWidth, i).toInt();

      if (resultingCoins > desiredNumberOfCoins) {
        break;
      }

      final desiredNumberOfCoinsAdjusted =
          desiredNumberOfCoins.toNthPowerOfTen(maxResultingCoinsPowerOfTen);
      final resultingCoinsAdjusted = resultingCoins.toNthPowerOfTen(maxResultingCoinsPowerOfTen);

      var difference = desiredNumberOfCoinsAdjusted - resultingCoinsAdjusted;
      if (difference < 0) {
        final resultingCoinsDigitsMinusOneToCompare =
            resultingCoins.toNthPowerOfTen(maxResultingCoinsPowerOfTen - 1);

        difference = desiredNumberOfCoinsAdjusted - resultingCoinsDigitsMinusOneToCompare;
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
    return waitForTransactionsAndGetFirstSpentIndex([coins.first.id]);
  }

  Future<int> waitForTransactionsAndGetFirstSpentIndex(List<Bytes> parentIds) async {
    final spentCoins = await blockchainUtils.waitForTransactions(parentIds);
    return spentCoins.map((c) => c.spentBlockIndex).reduce(min);
  }

  static int calculateNumberOfDecaSplitsRequired(
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
    required List<Puzzlehash> puzzlehashes,
  }) {
    if (max(splitWidth, 10) > puzzlehashes.length) {
      throw ArgumentError('not enough puzzlehashes to cover split width');
    }
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
}

extension PowersOfTen on num {
  num toNthPowerOfTen(int nthPowerOfTen) {
    final base10Upper = pow(10, nthPowerOfTen);
    final base10Lower = pow(10, nthPowerOfTen - 1);
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

  int get powerOfTen {
    var place = 0;

    var reduced = this;

    while (reduced >= 1) {
      reduced /= 10;
      place++;
    }
    return place;
  }
}
