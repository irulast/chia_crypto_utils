// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/origin_id_not_in_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/duplicate_coin_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/failed_signature_verification.dart';
import 'package:get_it/get_it.dart';

class BaseWalletService {
  BlockchainNetwork get blockchainNetwork => GetIt.I.get<BlockchainNetwork>();

  SpendBundle createSpendBundleBase({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    Puzzlehash? changePuzzlehash,
    bool allowLeftOver = false,
    int fee = 0,
    int surplus = 0,
    Bytes? originId,
    List<Bytes> coinIdsToAssert = const [],
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert =
        const [],
    List<Condition> additionalConditions = const [],
    required Program Function(Puzzlehash puzzlehash)
        makePuzzleRevealFromPuzzlehash,
    Program Function(Program standardSolution)? transformStandardSolution,
    // required JacobianPoint Function(CoinSpend coinSpend) makeSignatureForCoinSpend,
    void Function(Bytes message)? useCoinMessage,
  }) {
    Program makeSolutionFromConditions(List<Condition> conditions) {
      final standardSolution =
          BaseWalletService.makeSolutionFromConditions(conditions);
      if (transformStandardSolution == null) {
        return standardSolution;
      }
      return transformStandardSolution(standardSolution);
    }

    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);
    final totalCoinValue =
        coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );
    final change = totalCoinValue - totalPaymentAmount - fee - surplus;

    if (changePuzzlehash == null && change > 0 && !allowLeftOver) {
      throw ChangePuzzlehashNeededException();
    }

    final spends = <CoinSpend>[];

    // returns -1 if originId is given but is not in coins
    final originIndex =
        originId == null ? 0 : coins.indexWhere((coin) => coin.id == originId);

    if (originIndex == -1) {
      throw OriginIdNotInCoinsException();
    }

    // origin coin should be processed first so move it to the front of the list
    if (originIndex != 0) {
      final originCoin = coins.removeAt(originIndex);
      coins.insert(0, originCoin);
    }

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    var first = true;
    for (var i = 0; i < coins.length; i++) {
      final coin = coins[i];

      Program? solution;
      // create output for origin coin
      if (first) {
        first = false;
        final conditions = <Condition>[];
        final createdCoins = <CoinPrototype>[];
        for (final payment in payments) {
          final sendCreateCoinCondition = payment.toCreateCoinCondition();
          conditions.add(sendCreateCoinCondition);
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: payment.puzzlehash,
              amount: payment.amount,
            ),
          );
        }

        if (change > 0 && changePuzzlehash != null) {
          conditions.add(CreateCoinCondition(changePuzzlehash, change));
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: changePuzzlehash,
              amount: change,
            ),
          );
        }

        if (fee > 0) {
          conditions.add(ReserveFeeCondition(fee));
        }

        conditions
          ..addAll(coinAnnouncementsToAssert)
          ..addAll(puzzleAnnouncementsToAssert)
          ..addAll(additionalConditions);

        // generate message for coin announcements by appending coin_ids
        // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/wallet.py#L383
        //   message: bytes32 = std_hash(b"".join(message_list))
        final existingCoinsMessage = coins.fold(
          Bytes.empty,
          (Bytes previousValue, coin) => previousValue + coin.id,
        );
        final createdCoinsMessage = createdCoins.fold(
          Bytes.empty,
          (Bytes previousValue, coin) => previousValue + coin.id,
        );
        final message =
            (existingCoinsMessage + createdCoinsMessage).sha256Hash();

        useCoinMessage?.call(message);
        conditions.add(CreateCoinAnnouncementCondition(message));

        for (final coinIdToAssert in coinIdsToAssert) {
          conditions
              .add(AssertCoinAnnouncementCondition(coinIdToAssert, message));
        }

        primaryAssertCoinAnnouncement =
            AssertCoinAnnouncementCondition(coin.id, message);

        solution = makeSolutionFromConditions(conditions);
      } else {
        solution = makeSolutionFromConditions(
          [primaryAssertCoinAnnouncement!],
        );
      }

      final puzzle = makePuzzleRevealFromPuzzlehash(coin.puzzlehash);
      final coinSpend =
          CoinSpend(coin: coin, puzzleReveal: puzzle, solution: solution);
      spends.add(coinSpend);
    }

    return SpendBundle(coinSpends: spends);
  }

  SpendBundleSignResult signSpendBundleWithPrivateKey(
    SpendBundle spendBundle,
    PrivateKey privateKey, {
    bool Function(CoinSpend coinSpend)? filterCoinSpends,
  }) {
    final privateKeyPuzzlehash = getPuzzleFromPk(privateKey.getG1()).hash();

    return _signSpendBundle(
      spendBundle,
      getPrivateKeyForPuzzlehash: (puzzlehash) {
        if (puzzlehash == privateKeyPuzzlehash) {
          return privateKey;
        }
        return null;
      },
      filterCoinSpends: filterCoinSpends,
    );
  }

  SpendBundleSignResult signSpendBundle(
    SpendBundle spendBundle,
    WalletKeychain keychain, {
    bool Function(CoinSpend coinSpend)? filterCoinSpends,
  }) {
    // final publicKeyToPrivateKey = <JacobianPoint, PrivateKey>{};

    // for (final walletVector in [
    //   ...keychain.unhardenedWalletVectors,
    //   ...keychain.hardenedWalletVectors
    // ]) {
    //   final privateKey = walletVector.childPrivateKey;
    //   final publicKey = privateKey.getG1();

    //   final syntheticPrivateKey = calculateSyntheticPrivateKey(privateKey);
    //   final syntheticPublicKey = syntheticPrivateKey.getG1();

    //   publicKeyToPrivateKey[publicKey] = privateKey;
    //   publicKeyToPrivateKey[syntheticPublicKey] = syntheticPrivateKey;
    // }

    return _signSpendBundle(
      spendBundle,
      getPrivateKeyForPuzzlehash: (puzzlehash) {
        return keychain.getWalletVector(puzzlehash)?.childPrivateKey;
      },
      filterCoinSpends: filterCoinSpends,
    );
  }

  SpendBundleSignResult _signSpendBundle(
    SpendBundle spendBundle, {
    required PrivateKey? Function(Puzzlehash puzzlehash)
        getPrivateKeyForPuzzlehash,
    bool Function(CoinSpend coinSpend)? filterCoinSpends,
  }) {
    PrivateKey? getPrivateKeyForPublicKey(JacobianPoint publicKey) {
      final puzzlehashAssumingSyntheticPk =
          getPuzzleForSyntheticPk(publicKey).hash();

      final privateKey =
          getPrivateKeyForPuzzlehash(puzzlehashAssumingSyntheticPk);

      if (privateKey != null) {
        return calculateSyntheticPrivateKey(privateKey);
      }

      final puzzlehashAssumingNonSyntheticPk =
          getPuzzleFromPk(publicKey).hash();

      return getPrivateKeyForPuzzlehash(puzzlehashAssumingNonSyntheticPk);
    }

    var totalSpendBundle = spendBundle;

    final aggSigMeConditionsWithFullMessages =
        <AggSigMeConditionWithFullMessage>[];

    final spendsToSign = filterCoinSpends != null
        ? spendBundle.coinSpends.where(filterCoinSpends)
        : spendBundle.coinSpends;

    for (final coinSpend in spendsToSign) {
      final output = coinSpend.outputProgram;
      final aggSigMeConditions = BaseWalletService.extractConditionsFromResult(
        output,
        AggSigMeCondition.isThisCondition,
        AggSigMeCondition.fromProgram,
      );

      for (final aggSigMeCondition in aggSigMeConditions) {
        final fullMessage = constructFullAggSigMeMessage(
            aggSigMeCondition.message, coinSpend.coin.id);
        aggSigMeConditionsWithFullMessages.add(
            AggSigMeConditionWithFullMessage(aggSigMeCondition, fullMessage));

        final privateKey =
            getPrivateKeyForPublicKey(aggSigMeCondition.publicKey);

        if (privateKey == null) {
          continue;
        }

        final signature = AugSchemeMPL.sign(privateKey, fullMessage);
        totalSpendBundle = totalSpendBundle.withSignature(signature);
      }
    }

    return SpendBundleSignResult(
      totalSpendBundle,
      aggSigMeConditionWithMessages: aggSigMeConditionsWithFullMessages,
    );
  }

  // SpendBundle signSpendBundleWithPrivateKey(SpendBundle spendBundle, PrivateKey privateKey) {
  //   final puzzleHash = getPuzzleFromPk(privateKey.getG1()).hash();
  //   return spendBundle.signPerCoinSpend((coinSpend) {
  //     final puzzleDriver = PuzzleDriver.match(coinSpend.puzzleReveal);
  //     if (puzzleDriver == null) {
  //       LoggingContext().error('Unsuported coin spend:${coinSpend.toSerializedJson()}');
  //       return null;
  //     }
  //     if (puzzleDriver.getP2Puzzle(coinSpend).hash() != puzzleHash) {
  //       throw SignException(
  //         'Private key $privateKey does not match coin spend p2Puzzlle: $puzzleHash',
  //       );
  //     }

  //     return makeSignature(privateKey, coinSpend);
  //   });
  // }

  // SpendBundle signSpendBundleFromSkUsingConditions(
  //   SpendBundle spendBundle,
  //   PrivateKey privateKey, {
  //   bool useSyntheticOffset = true,
  // }) {
  //   return spendBundle.signPerCoinSpend((coinSpend) {
  //     final output = coinSpend.outputProgram;
  //     final aggSigMeConditions = BaseWalletService.extractConditionsFromResult(
  //       output,
  //       AggSigMeCondition.isThisCondition,
  //       AggSigMeCondition.fromProgram,
  //     );
  //     final privateKey_ =
  //         useSyntheticOffset ? calculateSyntheticPrivateKey(privateKey) : privateKey;

  //     final publicKey = privateKey_.getG1();

  //     for (final aggSigMeCondition in aggSigMeConditions) {
  //       if (aggSigMeCondition.publicKey != publicKey) {
  //         continue;
  //       }
  //       final fullMessage =
  //           constructFullAggSigMeMessage(aggSigMeCondition.message, coinSpend.coin.id);

  //       final isMet = AugSchemeMPL.verify(
  //         aggSigMeConditions.first.publicKey,
  //         fullMessage,
  //         spendBundle.aggregatedSignature!,
  //       );

  //       if (!isMet) {
  //         spendBundle.addSignature(AugSchemeMPL.sign(privateKey0, fullMessage));
  //       }
  //     }
  //   });
  // }

  JacobianPoint makeSignature(
    PrivateKey privateKey,
    CoinSpend coinSpend, {
    bool useSyntheticOffset = true,
  }) {
    final privateKey0 = useSyntheticOffset
        ? calculateSyntheticPrivateKey(privateKey)
        : privateKey;

    final messagesToSign = getAddSigMeMessage(coinSpend, privateKey0);

    final signatures = <JacobianPoint>[];

    for (final message in messagesToSign) {
      final signature = AugSchemeMPL.sign(privateKey0, message);
      signatures.add(signature);
    }

    return AugSchemeMPL.aggregate(signatures);
  }

  Bytes constructFullAggSigMeMessage(Bytes baseMessage, Bytes coinId) {
    return baseMessage +
        coinId +
        Bytes.fromHex(blockchainNetwork.aggSigMeExtraData);
  }

  List<Bytes> getAddSigMeMessage(CoinSpend coinSpend, PrivateKey privateKey) {
    final result = coinSpend.puzzleReveal.run(coinSpend.solution).program;
    final coin = coinSpend.coin;

    final aggSigMeConditions = result.toList().where((conditionProgram) {
      return AggSigMeCondition.isThisCondition(conditionProgram) &&
          AggSigMeCondition.fromProgram(conditionProgram).publicKey ==
              privateKey.getG1();
    }).map(AggSigMeCondition.fromProgram);

    if (aggSigMeConditions.length > 1) {
      print(
          'multiple agg sig me conditions: ${aggSigMeConditions.map((e) => e.toProgram())}');
      return [
        constructFullAggSigMeMessage(aggSigMeConditions.last.message, coin.id),
      ];
    }

    return aggSigMeConditions
        .map(
          (e) => constructFullAggSigMeMessage(e.message, coin.id),
        )
        .toList();

    // return constructFullAggSigMeMessage(aggSigMeConditions.first.message, coin.id);
  }

  static Program makeSolutionFromConditions(List<Condition> conditions) {
    return makeSolutionFromProgram(
      Program.list([
        Program.fromBigInt(keywords['q']!),
        ...conditions.map((condition) => condition.toProgram()),
      ]),
    );
  }

  static List<T> extractConditionsFromSolution<T>(
    Program solution,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    final programList = solution.toList();
    if (programList.length < 2) {
      return [];
    }
    return extractConditionsFromResult(
      programList[1],
      conditionChecker,
      conditionFromProgramConstructor,
    );
  }

  static List<Payment> extractPaymentsFromSolution(Program solution) {
    return BaseWalletService.extractConditionsFromSolution(
      solution,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    ).map((e) => e.toPayment()).toList();
  }

  static List<T> extractConditionsFromResult<T>(
    Program result,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    return result
        .toList()
        .where(conditionChecker)
        .map((p) => conditionFromProgramConstructor(p))
        .toList();
  }

  static List<T> extractConditionsFromProgramList<T>(
    List<Program> result,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    return result
        .where(conditionChecker)
        .map((p) => conditionFromProgramConstructor(p))
        .toList();
  }

  static Program makeSolutionFromProgram(Program program) {
    return Program.list([
      Program.nil,
      program,
      Program.nil,
    ]);
  }

  void validateSpendBundleSignature(SpendBundle spendBundle) {
    final publicKeys = <JacobianPoint>[];
    final messages = <List<int>>[];
    for (final spend in spendBundle.coinSpends) {
      final outputConditions =
          spend.puzzleReveal.run(spend.solution).program.toList();

      // look for assert agg sig me condition
      final aggSigMeProgram =
          outputConditions.singleWhere(AggSigMeCondition.isThisCondition);

      final aggSigMeCondition = AggSigMeCondition.fromProgram(aggSigMeProgram);
      publicKeys.add(aggSigMeCondition.publicKey);
      messages.add(
        aggSigMeCondition.message +
            spend.coin.id +
            Bytes.fromHex(blockchainNetwork.aggSigMeExtraData),
      );
    }

    // validate signature
    if (!AugSchemeMPL.aggregateVerify(
      publicKeys,
      messages,
      spendBundle.aggregatedSignature!,
    )) {
      throw FailedSignatureVerificationException();
    }
  }

  static void checkForDuplicateCoins(List<CoinPrototype> coins) {
    final idSet = <String>{};
    for (final coin in coins) {
      final coinIdHex = coin.id.toHex();
      if (idSet.contains(coinIdHex)) {
        throw DuplicateCoinException(coinIdHex);
      } else {
        idSet.add(coinIdHex);
      }
    }
  }
}

class CoinSpendAndSignature {
  const CoinSpendAndSignature(this.coinSpend, this.signature);

  final CoinSpend coinSpend;
  final JacobianPoint signature;
}
