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

    final resultingCoinsFromNWidthSplits = pow(splitWidth, numberOfNWidthSplits).toInt();
    final numberOfDecaSplits =
        calculateNumberOfDecaSplitsRequired(resultingCoinsFromNWidthSplits, desiredNumberOfCoins);

    final airdropId = catCoinToSplit.id;
    final airdropFeeCoinsId = standardCoinsForFee.joinedIds.sha256Hash();

    await createAndPushStandardCoinJoinTransaction(
      coins: standardCoinsForFee,
      keychain: keychain,
      destinationPuzzlehash: keychain.puzzlehashes.first,
      airdropFeeCoinsId: airdropFeeCoinsId,
    );

    var catCoins = [catCoinToSplit];
    var standardCoins = await fullNode.getCoinsByMemo(airdropFeeCoinsId);

    for (var i = 0; i < numberOfNWidthSplits; i++) {
      await createAndPushSplittingTransactions(
        catCoins: catCoins,
        standardCoinsForFee: standardCoins,
        keychain: keychain,
        splitWidth: 2,
        feePerCoin: 100,
        airdropId: airdropId,
        airdropFeeCoinsId: airdropFeeCoinsId,
      );
      catCoins = await fullNode.getCatCoinsByMemo(airdropId);
      standardCoins = await fullNode.getCoinsByMemo(airdropFeeCoinsId);
    }

    for (var i = 0; i < numberOfDecaSplits; i++) {
      await createAndPushSplittingTransactions(
        catCoins: catCoins,
        standardCoinsForFee: standardCoins,
        keychain: keychain,
        splitWidth: 10,
        feePerCoin: 100,
        airdropId: airdropId,
        airdropFeeCoinsId: airdropFeeCoinsId,
      );
      catCoins = await fullNode.getCatCoinsByMemo(airdropId);
      standardCoins = await fullNode.getCoinsByMemo(airdropFeeCoinsId);
    }

    await createAndPushFinalSplittingTransactions(
      catCoins: catCoins,
      standardCoinsForFee: standardCoins,
      keychain: keychain,
      feePerCoin: 100,
      airdropId: airdropId,
      desiredAmountPerCoin: desiredAmountPerCoin,
      desiredNumberOfCoins: desiredNumberOfCoins,
      changePuzzlehash: keychain.puzzlehashes.first,
    );
  }

  Future<void> createAndPushFinalSplittingTransactions({
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
    final additionIdsToLookFor = <Bytes>[];

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
            memos: <Bytes>[airdropId],
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
        fee: 10 * feePerCoin,
      );
      additionIdsToLookFor.add(spendBundle.additions.first.id);

      transactionFutures.add(fullNode.pushTransaction(spendBundle));
      if (isFinished) {
        break;
      }
    }
    await Future.wait<void>(transactionFutures);
    await waitForTransactions(additionIdsToLookFor);
  }

  Future<void> createAndPushSplittingTransactions({
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
    final additionIdsToLookFor = <Bytes>[];
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
      final standardCoinsTotalValueMinusFee = standardCoinsForFee.totalValue - totalFeeAmount;

      final standardPayments = <Payment>[];
      for (var i = 0; i < splitWidth - 1; i++) {
        standardPayments.add(
          Payment(
            standardCoinsTotalValueMinusFee ~/ splitWidth,
            keychain.puzzlehashes[i],
            memos: <Bytes>[airdropFeeCoinsId],
          ),
        );
      }
      final lastStandardPaymentAmount =
          standardCoinsTotalValueMinusFee - standardPayments.totalValue;
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
      additionIdsToLookFor.add(spendBundle.additions.first.id);
      transactionFutures.add(fullNode.pushTransaction(spendBundle + standardSpendBundle));
    }
    await Future.wait<void>(transactionFutures);

    // wait for all spend bundles to be pushed
    await waitForTransactions(additionIdsToLookFor);
  }

  Future<void> waitForTransactions(List<Bytes> additionIdsToLookFor) async {
    final unfoundIds = Set<Bytes>.from(additionIdsToLookFor);

    while (unfoundIds.isNotEmpty) {
      final foundCoins = await fullNode.getCoinsByIds(unfoundIds.toList());
      final foundIds = foundCoins.map((c) => c.id).toSet();
      unfoundIds.removeWhere(foundIds.contains);

      await Future<void>.delayed(const Duration(seconds: 19));
      print('waiting for transactions to be included...');
    }
  }

  int calculateNumberOfNWidthSplitsRequired({
    required int desiredNumberOfCoins,
    required int initialSplitWidth,
  }) {
    late int numberOfBinarySplits;
    num smallestDifference = 10000000;

    for (var i = 0; i < 10; i++) {
      final resultingCoins = pow(initialSplitWidth, i).toInt();

      if (resultingCoins > desiredNumberOfCoins) {
        break;
      }

      final desiredNumberOfCoinsDigitsToCompare = desiredNumberOfCoins.toNDigits(3);

      final resultingCoinsDigitsToCompare = resultingCoins.toNDigits(3);

      var difference = desiredNumberOfCoinsDigitsToCompare - resultingCoinsDigitsToCompare;
      if (difference < 0 && resultingCoins.numberOfDigits > 1) {
        final resultingCoinsDigitsMinusOneToCompare =
            //TODO(nvjoshi): fix this
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

  Future<void> createAndPushStandardCoinJoinTransaction({
    required List<Coin> coins,
    required WalletKeychain keychain,
    required Puzzlehash destinationPuzzlehash,
    int fee = 0,
    required Bytes airdropFeeCoinsId,
  }) async {
    final totalAmountMinusFee = coins.totalValue - fee;
    final joinSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(totalAmountMinusFee, destinationPuzzlehash)],
      coinsInput: coins,
      keychain: keychain,
      fee: fee,
    );

    await fullNode.pushTransaction(joinSpendBundle);
    await waitForTransactions([joinSpendBundle.additions.first.id]);
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
