// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_crypto_utils/src/cat/models/conditions/run_tail_condition.dart';
import 'package:chia_crypto_utils/src/cat/models/tail_info.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/core/exceptions/insufficient_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/incorrect_announcement_id_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';

abstract class CatWalletService extends BaseWalletService {
  CatWalletService(
      this.catProgram, this.spendType, this.innerPuzzleAnnouncementMorphBytes);

  factory CatWalletService.fromCatProgram(Program catProgram) {
    if (catProgram == cat2Program) {
      return Cat2WalletService();
    }
    if (catProgram == catProgram) {
      return Cat1WalletService();
    }
    throw Exception('invalid cat program');
  }

  factory CatWalletService.fromCatVersion(int version) {
    switch (version) {
      case 1:
        return Cat1WalletService();
      case 2:
        return Cat2WalletService();
      default:
        throw Exception('unsupported cat version: $version');
    }
  }
  final StandardWalletService standardWalletService = StandardWalletService();
  final Program catProgram;
  final SpendType spendType;
  final Bytes? innerPuzzleAnnouncementMorphBytes;

  bool validateCat(CatCoin catCoin) {
    return catCoin.catProgram == catProgram;
  }

  int get catVersion {
    if (catProgram == cat2Program) {
      return 2;
    }
    if (catProgram == cat1Program) {
      return 1;
    }

    throw Exception('invalid cat program');
  }

  static List<Payment> getPaymentsForCoinSpend(CoinSpend coinSpend) {
    final innerSolution = coinSpend.solution.toList()[0];

    return BaseWalletService.extractPaymentsFromSolution(innerSolution);
  }

  void _addOuterPuzzlehashesToKeychainForCats({
    required List<CatCoin> catCoinsInput,
    required WalletKeychain keychain,
  }) {
    if (catCoinsInput.isEmpty) {
      return;
    }
    try {
      final catInnerPuzzlehashes =
          catCoinsInput.map((e) => e.getP2PuzzlehashSync());
      keychain.addOuterPuzzleHashesForInnerPuzzleHashesGeneric(
        catInnerPuzzlehashes.toList(),
        catCoinsInput.first.assetId,
        catProgram,
      );
    } catch (e) {
      LoggingContext().error(
          'Error adding outer puzzlehashes to keychain for cats in fallback: $e');
    }
  }

  SpendBundle createSpendBundle({
    required List<CatPayment> payments,
    required List<CatCoin> catCoinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    List<CoinPrototype> standardCoinsForFee = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert =
        const [],
    List<Condition> additionalConditions = const [],
    int fee = 0,
    bool shouldAddCatOuterPuzzlehashesToKeychain = true,
  }) {
    final distinctAssetIds = catCoinsInput.map((c) => c.assetId).toSet();
    if (distinctAssetIds.length != 1) {
      throw MixedAssetIdsException(distinctAssetIds);
    }

    if (shouldAddCatOuterPuzzlehashesToKeychain) {
      _addOuterPuzzlehashesToKeychainForCats(
        catCoinsInput: catCoinsInput,
        keychain: keychain,
      );
    }

    final totalCatPaymentAmount = payments.fold(
        0, (int previousValue, payment) => previousValue + payment.amount);

    final catCoins = List<CatCoin>.from(catCoinsInput);

    final totalCatCoinValue = catCoins.fold(
      0,
      (int previousValue, coin) => previousValue + coin.amount,
    );

    if (totalCatCoinValue < totalCatPaymentAmount) {
      throw InsufficientCoinsException(
        attemptedSpendAmount: totalCatPaymentAmount,
        coinTotalValue: totalCatCoinValue,
      );
    }

    final change = totalCatCoinValue - totalCatPaymentAmount;
    if (changePuzzlehash == null && change != 0) {
      throw ChangePuzzlehashNeededException();
    }
    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    SpendBundle? feeStandardSpendBundle;

    final spendableCats = <SpendableCat>[];
    var first = true;
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVector(catCoin.puzzlehash) ??
          keychain.getWalletVectorOrThrow(catCoin.getP2PuzzlehashSync());
      final coinPublicKey = coinWalletVector.childPublicKey;

      Program? innerSolution;
      // if first coin, make inner solution with output
      if (first) {
        first = false;
        // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/cat_wallet/cat_wallet.py#L646
        //   announcement = Announcement(coin.name(), std_hash(b"".join([c.name() for c in cat_coins])), b"\xca")
        final message = catCoins
            .fold(
              Bytes.empty,
              (Bytes previousValue, coin) => previousValue + coin.id,
            )
            .sha256Hash();

        primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(
          catCoin.id,
          message,
          // https://chialisp.com/docs/puzzles/cats under "Design Choices"
          morphBytes: innerPuzzleAnnouncementMorphBytes,
        );

        final conditions = <Condition>[];
        final createdCoins = <CoinPrototype>[];

        conditions
          ..add(CreateCoinAnnouncementCondition(
              primaryAssertCoinAnnouncement.message))
          ..addAll(puzzleAnnouncementsToAssert)
          ..addAll(additionalConditions);

        if (change > 0) {
          payments.add(CatPayment(change, changePuzzlehash!));
        }

        for (final payment in payments) {
          final sendCreateCoinCondition = payment.toCreateCoinCondition();
          conditions.add(sendCreateCoinCondition);
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: catCoin.id,
              puzzlehash: payment.puzzlehash,
              amount: payment.amount,
            ),
          );
        }

        if (fee > 0) {
          feeStandardSpendBundle = _makeStandardSpendBundleForFee(
            fee: fee,
            standardCoins: standardCoinsForFee,
            keychain: keychain,
            changePuzzlehash: changePuzzlehash,
          );
        }

        innerSolution =
            BaseWalletService.makeSolutionFromConditions(conditions);
      } else {
        innerSolution = BaseWalletService.makeSolutionFromConditions(
            [primaryAssertCoinAnnouncement!]);
      }

      final innerPuzzle = getPuzzleFromPk(coinPublicKey);

      spendableCats.add(
        SpendableCat(
          coin: catCoin,
          innerPuzzle: innerPuzzle,
          innerSolution: innerSolution,
        ),
      );
    }

    final immutableSpendableCats =
        List<SpendableCat>.unmodifiable(spendableCats);

    final catSpendBundle =
        makeUnsignedSpendBundleForSpendableCats(immutableSpendableCats);

    if (feeStandardSpendBundle != null) {
      final combinedSpendBundle = catSpendBundle + feeStandardSpendBundle;

      final signedSpendBundle = combinedSpendBundle.sign(keychain).signedBundle;
      return signedSpendBundle;
    }
    return catSpendBundle.sign(keychain).signedBundle;
  }

  IssuanceResult makeMultiIssuanceCatSpendBundle({
    required Bytes genesisCoinId,
    required List<CoinPrototype> standardCoins,
    required PrivateKey privateKey,
    required Puzzlehash destinationPuzzlehash,
    required Puzzlehash changePuzzlehash,
    required int amount,
    required WalletKeychain keychain,
    int fee = 0,
  }) {
    final publicKey = privateKey.getG1();
    final curriedTail =
        delegatedTailProgram.curry([Program.fromAtom(publicKey.toBytes())]);

    final curriedGenesisByCoinId =
        genesisByCoinIdProgram.curry([Program.fromAtom(genesisCoinId)]);
    final tailSolution = Program.list([curriedGenesisByCoinId, Program.nil]);

    final signature =
        AugSchemeMPL.sign(privateKey, curriedGenesisByCoinId.hash());

    final spendBundle = makeIssuanceSpendbundle(
      tail: curriedTail,
      solution: tailSolution,
      standardCoins: standardCoins,
      destinationPuzzlehash: destinationPuzzlehash,
      changePuzzlehash: changePuzzlehash,
      amount: amount,
      makeSignature: (_) => signature,
      keychain: keychain,
      originId: genesisCoinId,
      fee: fee,
    );

    return IssuanceResult(
      spendBundle: spendBundle,
      tailRunningInfo: TailRunningInfo(
        tail: curriedTail,
        signature: signature,
        tailSolution: tailSolution,
      ),
    );
  }

  IssuanceResult makeMeltableMultiIssuanceCatSpendBundle({
    required Bytes genesisCoinId,
    required List<CoinPrototype> standardCoins,
    required PrivateKey privateKey,
    required Puzzlehash destinationPuzzlehash,
    required Puzzlehash changePuzzlehash,
    required int amount,
    required WalletKeychain keychain,
    int fee = 0,
  }) {
    final publicKey = privateKey.getG1();
    final curriedTail =
        delegatedTailProgram.curry([Program.fromAtom(publicKey.toBytes())]);

    final curriedMeltableGenesisByCoinIdPuzzle =
        meltableGenesisByCoinIdProgram.curry([Program.fromAtom(genesisCoinId)]);
    final tailSolution =
        Program.list([curriedMeltableGenesisByCoinIdPuzzle, Program.nil]);

    final issuanceSignature = AugSchemeMPL.sign(
      privateKey,
      curriedMeltableGenesisByCoinIdPuzzle.hash(),
    );
    final spendBundle = makeIssuanceSpendbundle(
      tail: curriedTail,
      solution: tailSolution,
      standardCoins: standardCoins,
      destinationPuzzlehash: destinationPuzzlehash,
      changePuzzlehash: changePuzzlehash,
      amount: amount,
      makeSignature: (_) => issuanceSignature,
      keychain: keychain,
      originId: genesisCoinId,
      fee: fee,
    );
    return IssuanceResult(
      spendBundle: spendBundle,
      tailRunningInfo: TailRunningInfo(
        tail: curriedTail,
        signature: issuanceSignature,
        tailSolution: tailSolution,
      ),
    );
  }

  SpendBundle makeMeltingSpendBundle({
    required CatCoin catCoinToMelt,
    required List<CoinPrototype> standardCoinsForXchClaimingSpendBundle,
    required Puzzlehash puzzlehashToClaimXchTo,
    required TailRunningInfo tailRunningInfo,
    required WalletKeychain keychain,
    Bytes? standardOriginId,
    int fee = 0,
    required Puzzlehash changePuzzlehash,
    int? inputAmountToMelt,
  }) {
    _addOuterPuzzlehashesToKeychainForCats(
        catCoinsInput: [catCoinToMelt], keychain: keychain);
    final amountToMelt = inputAmountToMelt ?? catCoinToMelt.amount;
    final catChange = catCoinToMelt.amount - amountToMelt;

    final walletVector = keychain.getWalletVector(catCoinToMelt.puzzlehash);

    final innerPuzzle = getPuzzleFromPk(walletVector!.childPublicKey);

    final conditions = <Condition>[
      RunTailCondition(
        tailRunningInfo.tail,
        tailRunningInfo.tailSolution,
      ),
    ];

    if (catChange > 0) {
      conditions.add(CreateCoinCondition(changePuzzlehash, catChange));
    }

    final innerSolution =
        BaseWalletService.makeSolutionFromConditions(conditions);

    final spendableCat = SpendableCat(
      coin: catCoinToMelt,
      innerPuzzle: innerPuzzle,
      innerSolution: innerSolution,
      extraDelta: -amountToMelt,
    );

    final meltSpendBundle =
        makeUnsignedSpendBundleForSpendableCats([spendableCat])
            .sign(keychain)
            .signedBundle;

    final totalStandardCoinValue =
        standardCoinsForXchClaimingSpendBundle.totalValue;

    final xchClaimingSpendbundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(totalStandardCoinValue - fee, changePuzzlehash),
        Payment(amountToMelt, puzzlehashToClaimXchTo),
      ],
      coinsInput: standardCoinsForXchClaimingSpendBundle,
      originId: standardOriginId,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
    );

    final finalSpendbundle = (meltSpendBundle + xchClaimingSpendbundle)
        .withSignature(tailRunningInfo.signature);

    return finalSpendbundle;
  }

  SpendBundle makeIssuanceSpendbundle({
    required Program tail,
    required Program solution,
    required List<CoinPrototype> standardCoins,
    required Puzzlehash destinationPuzzlehash,
    required Puzzlehash changePuzzlehash,
    required int amount,
    required JacobianPoint Function(CoinPrototype eveCoin) makeSignature,
    required WalletKeychain keychain,
    Bytes? originId,
    int fee = 0,
  }) {
    final payToPuzzle = Program.cons(
      Program.fromInt(1),
      Program.list([
        Program.list(
          [
            Program.fromInt(51),
            Program.fromInt(0),
            Program.fromInt(-113),
            tail,
            solution
          ],
        ),
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(destinationPuzzlehash),
          Program.fromInt(amount),
          Program.list([
            Program.fromAtom(destinationPuzzlehash),
          ]),
        ]),
      ]),
    );

    final catPuzzle = makeCatPuzzle(tail.hash(), payToPuzzle);
    final catPuzzleHash = Puzzlehash(catPuzzle.hash());

    final standardCoinOriginId = originId ?? standardCoins[0].id;
    final standardSpendBundle = standardWalletService.createSpendBundle(
      payments: [CatPayment(amount, Puzzlehash(catPuzzle.hash()))],
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      originId: standardCoinOriginId,
      fee: fee,
    );

    final eveParentSpend = standardSpendBundle.coinSpends
        .singleWhere((spend) => spend.coin.id == standardCoinOriginId);

    final eveCoin = CoinPrototype(
      parentCoinInfo: standardCoinOriginId,
      puzzlehash: catPuzzleHash,
      amount: amount,
    );

    final eveCatCoin = CatCoin.eve(
      parentCoinSpend: eveParentSpend,
      coin: eveCoin,
      assetId: Puzzlehash(tail.hash()),
      catProgram: catProgram,
    );

    final spendableEve = SpendableCat(
        coin: eveCatCoin, innerPuzzle: payToPuzzle, innerSolution: Program.nil);

    final eveUnsignedSpendbundle =
        makeUnsignedSpendBundleForSpendableCats([spendableEve]);

    final finalSpendBundle = (standardSpendBundle + eveUnsignedSpendbundle)
        .withSignature(makeSignature(eveCoin));

    return finalSpendBundle;
  }

  SpendBundle makeUnsignedSpendBundleForSpendableCats(
      List<SpendableCat> spendableCats) {
    SpendableCat.calculateAndAttachSubtotals(spendableCats);

    final spends = <CoinSpend>[];

    final n = spendableCats.length;
    for (var index = 0; index < n; index++) {
      final previousIndex = (index - 1) % n;
      final nextIndex = (index + 1) % n;

      final previousSpendableCat = spendableCats[previousIndex];
      final currentSpendableCat = spendableCats[index];
      final nextSpendableCat = spendableCats[nextIndex];

      final puzzleReveal = makeCatPuzzleFromSpendableCat(currentSpendableCat);

      final solution = makeCatSolution(
        previousSpendableCat: previousSpendableCat,
        currentSpendableCat: currentSpendableCat,
        nextSpendableCat: nextSpendableCat,
      );
      final coinSpend = CoinSpend(
        coin: currentSpendableCat.coin,
        puzzleReveal: puzzleReveal,
        solution: solution,
      );
      spends.add(coinSpend);
    }
    return SpendBundle(coinSpends: spends);
  }

  SpendBundle _makeStandardSpendBundleForFee({
    required int fee,
    required List<CoinPrototype> standardCoins,
    required WalletKeychain keychain,
    required Puzzlehash? changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAsset = const [],
  }) {
    assert(
      standardCoins.isNotEmpty,
      'If passing in a fee, you must also pass in standard coins to use for that fee.',
    );

    final totalStandardCoinsValue = standardCoins.fold(
      0,
      (int previousValue, standardCoin) => previousValue + standardCoin.amount,
    );
    assert(
      totalStandardCoinsValue >= fee,
      'Total value of passed in standad coins is not enough to cover fee.',
    );

    return standardWalletService.createUnsignedSpendBundle(
      payments: [],
      coinsInput: standardCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
    );
  }

  static Program makeCatSolution({
    required SpendableCat previousSpendableCat,
    required SpendableCat currentSpendableCat,
    required SpendableCat nextSpendableCat,
  }) {
    assert(
      currentSpendableCat.subtotal != null,
      'subtotal has not been attached to currentSpendableCat',
    );
    // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/cat_wallet/cat_utils.py#L123
    return Program.list([
      currentSpendableCat.innerSolution,
      currentSpendableCat.coin.lineageProof,
      Program.fromAtom(previousSpendableCat.coin.id),
      currentSpendableCat.coin.toProgram(),
      nextSpendableCat.makeStandardCoinProgram(),
      Program.fromInt(currentSpendableCat.subtotal!),
      Program.fromInt(
        currentSpendableCat.extraDelta,
      ), // limitations_program_reveal: unused since we're not handling any cat discrepancy
    ]);
  }

  Program makeCatPuzzleFromSpendableCat(SpendableCat spendableCat) {
    return makeCatPuzzle(spendableCat.coin.assetId, spendableCat.innerPuzzle);
  }

  Program makeCatPuzzle(Puzzlehash assetId, Program innerPuzzle) {
    return makeCatPuzzleFromParts(
      catProgram: catProgram,
      innerPuzzle: innerPuzzle,
      assetId: assetId,
    );
  }

  static Program makeCatPuzzleFromParts({
    required Program catProgram,
    required Program innerPuzzle,
    required Puzzlehash assetId,
  }) {
    return catProgram.curry([
      Program.fromAtom(catProgram.hash()),
      Program.fromAtom(assetId),
      innerPuzzle
    ]);
  }

  void validateSpendBundle(SpendBundle spendBundle) {
    validateSpendBundleSignature(spendBundle);

    // validate assert_coin_announcement if it is created (if there are multiple coins spent)
    List<Bytes>? actualAssertCoinAnnouncementIds;
    final coinsToCreate = <CoinPrototype>[];
    final coinsBeingSpent = <CoinPrototype>[];
    Bytes? originId;
    final catSpends =
        spendBundle.coinSpends.where((spend) => spend.type == spendType);
    for (final catSpend in catSpends) {
      final outputConditions =
          catSpend.puzzleReveal.run(catSpend.solution).program.toList();

      // find create_coin conditions
      final coinCreationConditions = outputConditions
          .where(CreateCoinCondition.isThisCondition)
          .map(CreateCoinCondition.fromProgram)
          .toList();

      for (final coinCreationCondition in coinCreationConditions) {
        coinsToCreate.add(
          CoinPrototype(
            parentCoinInfo: catSpend.coin.id,
            puzzlehash: coinCreationCondition.destinationPuzzlehash,
            amount: coinCreationCondition.amount,
          ),
        );
      }
      coinsBeingSpent.add(catSpend.coin);

      if (coinCreationConditions.isNotEmpty) {
        // if originId is already set, multiple coins are creating output which is invalid
        if (originId != null) {
          throw MultipleOriginCoinsException();
        }
        originId = catSpend.coin.id;
      }

      // origin id doesn't contain its own assert coin announcement
      if (catSpend.coin.id != originId) {
        final assertCoinAnnouncementPrograms = outputConditions
            .where(AssertCoinAnnouncementCondition.isThisCondition)
            .toList();

        // set actualAssertCoinAnnouncementIds only if it is null
        actualAssertCoinAnnouncementIds ??= assertCoinAnnouncementPrograms
            .map(AssertCoinAnnouncementCondition.getAnnouncementIdFromProgram)
            .toList();
      }
      // look for assert coin announcement condition
    }

    // check for duplicate coins
    BaseWalletService.checkForDuplicateCoins(coinsToCreate);
    BaseWalletService.checkForDuplicateCoins(coinsBeingSpent);

    if (catSpends.length > 1) {
      assert(
        actualAssertCoinAnnouncementIds != null,
        'No assert_coin_announcement condition when multiple spends',
      );
      assert(originId != null, 'No create_coin conditions');

      // construct assert_coin_announcement id from spendbundle, verify against output
      final existingCoinsMessage = coinsBeingSpent.fold(
        Bytes.empty,
        (Bytes previousValue, coin) => previousValue + coin.id,
      );

      final message = existingCoinsMessage.sha256Hash();

      final constructedAnnouncement = AssertCoinAnnouncementCondition(
        originId!,
        message,
        morphBytes: innerPuzzleAnnouncementMorphBytes,
      );

      if (!actualAssertCoinAnnouncementIds!
          .contains(constructedAnnouncement.announcementId)) {
        throw IncorrectAnnouncementIdException();
      }
    }
  }

  DeconstructedCatPuzzle? matchCatPuzzle(Program catPuzzle) {
    final uncurried = catPuzzle.uncurry();

    final uncurriedPuzzle = uncurried.mod;
    if (uncurriedPuzzle != catProgram) {
      return null;
    }

    return DeconstructedCatPuzzle(
      uncurriedPuzzle: uncurriedPuzzle,
      assetId: Puzzlehash(uncurried.arguments[1].atom),
      innerPuzzle: uncurried.arguments[2],
      catProgram: catProgram,
    );
  }
}

class DeconstructedCatPuzzle {
  DeconstructedCatPuzzle({
    required Program uncurriedPuzzle,
    required this.assetId,
    required this.innerPuzzle,
    required this.catProgram,
  }) : uncurriedPuzzle = (uncurriedPuzzle == catProgram)
            ? uncurriedPuzzle
            : throw ArgumentError('Supplied puzzle is not cat puzzle');
  final Program uncurriedPuzzle;
  final Puzzlehash assetId;
  final Program innerPuzzle;
  final Program catProgram;
}

class IssuanceResult {
  IssuanceResult({
    required this.spendBundle,
    required this.tailRunningInfo,
  });

  final SpendBundle spendBundle;
  final TailRunningInfo tailRunningInfo;
}
