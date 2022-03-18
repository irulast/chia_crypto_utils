import 'dart:math';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/cat/models/spedable_cat.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/payment.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';

class CatWalletService extends BaseWalletService {
  late StandardWalletService standardWalletService;
  
  CatWalletService(Context context) : super(context) {
    standardWalletService = StandardWalletService(context);
  }

  SpendBundle createSpendBundle(
    List<Payment> payments, 
     List<CatCoin> catCoinsInput, 
    Puzzlehash changePuzzlehash, 
    WalletKeychain keychain, 
    {
      List<Coin> standardCoinsForFee = const [], 
      int fee = 0, 
    }
    ) {
      return _createSpendBundle(
        payments, 
        catCoinsInput, 
        changePuzzlehash,
        keychain,
        standardCoinsForFee: standardCoinsForFee,
        fee: fee,
      );
    }

  SpendBundle _createSpendBundle(
    List<Payment> payments, 
    List<CatCoin> catCoinsInput, 
    Puzzlehash changePuzzlehash, 
    WalletKeychain keychain, 
    {
      List<Coin> standardCoinsForFee = const [], 
      int fee = 0, 
    }
    ) {
    final spendBundlesToAggregate = <SpendBundle>[];
    if (fee > 0) {
      assert(standardCoinsForFee.isNotEmpty, 'If passing in a fee, you must also pass in standard coins to use for that fee.');
      final totalStandardCoinsValue = standardCoinsForFee.fold(0, (int previousValue, standardCoin) => previousValue + standardCoin.amount);
      assert(totalStandardCoinsValue >= fee, 'Total value of passed in standad coins is not enough to cover fee.');

      final spendBundleForFee = standardWalletService.createSpendBundle(standardCoinsForFee, 0, Address.fromPuzzlehash(changePuzzlehash, blockchainNetwork.addressPrefix), changePuzzlehash, keychain, fee: fee);
      spendBundlesToAggregate.add(spendBundleForFee);
    }

    final totalPaymentAmount = payments.fold(0, (int previousValue, payment) => previousValue + payment.amount);

    final catCoins = List<CatCoin>.from(catCoinsInput);

    final distinctAssetIds = catCoins.map((c) => c.assetId).toSet();
    if(distinctAssetIds.length != 1) {
      throw MixedAssetIdsException(distinctAssetIds);
    }
    final totalCatCoinValue = catCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final change = totalCatCoinValue - totalPaymentAmount;

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    final spendableCats = <SpendableCat>[];

    var first = true;
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVector(catCoin.puzzlehash);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;
      final coinPublicKey = coinPrivateKey.getG1();

      Program? innerSolution;
      // if first coin, make inner solution with output
      if (first) {
        first = false;

        final message = catCoins.fold(
          Puzzlehash.empty, 
          (Puzzlehash previousValue, coin) => previousValue + coin.id,
        ).sha256Hash();

        primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(
          catCoin.id,
          message,
          morphBytes: const Puzzlehash([202]),
        );
          

        final conditions = <Condition>[];
        final createdCoins = <CoinPrototype>[];

        conditions.add(CreateCoinAnnouncementCondition(primaryAssertCoinAnnouncement.message));

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

        if (change > 0) {
          conditions.add(CreateCoinCondition(changePuzzlehash, change));
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: catCoin.id,
              puzzlehash: changePuzzlehash,
              amount: change,
            ),
          );
        }

        innerSolution = BaseWalletService.makeSolutionFromConditions(conditions);
      } else {
        innerSolution = BaseWalletService.makeSolutionFromConditions([primaryAssertCoinAnnouncement!]);
      }
      print(innerSolution.toSource());

      final innerPuzzle = getPuzzleFromPk(coinPublicKey);

      spendableCats.add(
        SpendableCat(
          coin: catCoin, 
          innerPuzzle: innerPuzzle, 
          innerSolution: innerSolution,
        ),
      );

      // final catPuzzle = makeCatPuzzle(innerPuzzle, catCoin.assetId);
      // final catSolution = makeCatSolution(innerPuzzle, innerSolution, catCoin);

      // final coinSpendAndSig = createCoinsSpendAndSignature(catSolution, catPuzzle, coinPrivateKey, catCoin);
      // spends.add(coinSpendAndSig.coinSpend);
      // signatures.add(coinSpendAndSig.signature);
    }
    final deltas = <int>[];
    for (final spendableCat in spendableCats)  {
      final conditionPrograms = spendableCat.innerPuzzle.run(spendableCat.innerSolution).program.toList();

      var total = 0;
      // print('coin amount: ${spendableCat.coin.amount}');
      for (final createCoinConditionProgram in conditionPrograms.where(CreateCoinCondition.isThisCondition)) {
        if (!createCoinConditionProgram.toSource().contains('-113')) {
          final createCoinCondition = CreateCoinCondition.fromProgram(createCoinConditionProgram);
          // print('condition amount: ${createCoinCondition.amount}');
          total += createCoinCondition.amount;
        }
      }
      deltas.add(spendableCat.coin.amount - total);
    }
    print(deltas);

    final subtotals = subtotalsForDeltas(deltas);
    print(subtotals);


    final infosForNext = <Program>[];
    final infosForMe = <Program>[];
    final ids = <Puzzlehash>[];
    for (final spendableCat in spendableCats) {
      infosForNext.add(spendableCat.standardCoinProgram);
      infosForMe.add(spendableCat.coin.toProgram());
      ids.add(spendableCat.coin.id);
    }

    final n = spendableCats.length;
    final spends = <CoinSpend>[];
    final signatures = <JacobianPoint>[];

    for (var index = 0; index < n; index++) {
      final spendInfo = spendableCats[index];

      final puzzleReveal = makeCatPuzzle(spendInfo.innerPuzzle, spendInfo.coin.assetId);

      final prevIndex = (index - 1) % n;
      final nextIndex = (index + 1) % n;
      final prevId = ids[prevIndex];
      final myInfo = infosForMe[index];
      final nextInfo = infosForNext[nextIndex];

      final solution = Program.list([
        spendInfo.innerSolution, 
        spendInfo.coin.lineageProof,
        Program.fromBytes(prevId.bytes),
        myInfo,
        nextInfo,
        Program.fromInt(subtotals[index]), 
        Program.fromInt(0), // limitations_program_reveal: unused since we're not handling any cat discrepancy
      ]);

      final coinWalletVector = keychain.getWalletVector(spendInfo.coin.puzzlehash);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;

      final solAndSig = createCoinsSpendAndSignature(solution, puzzleReveal, coinPrivateKey, spendInfo.coin);

      spends.add(solAndSig.coinSpend);
      signatures.add(solAndSig.signature);
    }

    final catAggregateSignature = AugSchemeMPL.aggregate(signatures);
    final catSpendBundle = SpendBundle(coinSpends: spends, aggregatedSignature: catAggregateSignature);

    spendBundlesToAggregate.add(catSpendBundle);

    return SpendBundle.aggregate(spendBundlesToAggregate);
  }

  // see chia/wallet/cc_wallet/cc_wallet.py: generate_unsigned_spendbundle
  static Program makeCatSolution(Program innerPuzzle, Program innerSolution, CatCoin catCoin) {
    return Program.list([
      innerSolution, 
      catCoin.lineageProof,
      Program.fromBytes(catCoin.id.bytes),
      catCoin.toProgram(),
      Program.list([Program.fromBytes(catCoin.parentCoinInfo.bytes), Program.fromBytes(innerPuzzle.hash()), Program.fromInt(catCoin.amount)]),
      Program.fromInt(0), // extra_delta: unused since we're not melting or issuing CATs
      Program.fromInt(0), // limitations_program_reveal: unused since we're not handling any cat discrepancy
    ]);
  }

  static Program makeCatPuzzle(Program innerPuzzle, Puzzlehash assetId) {
    return catProgram.curry([
      Program.fromBytes(catProgram.hash()),
      Program.fromBytes(assetId.bytes),
      innerPuzzle
    ]);
  }

  static List<int> subtotalsForDeltas(List<int> deltas){
    if (deltas.isEmpty) {
      return [];
    }

    final subtotals = <int>[];
    var subtotal = 0;

    for (final delta in deltas) {
        subtotals.add(subtotal);
        subtotal += delta;
    }

    // tweak the subtotals so the smallest value is 0
    final subtotalOffset = subtotals.reduce(min);
    return subtotals.map((s) => s - subtotalOffset).toList();
  }
}
