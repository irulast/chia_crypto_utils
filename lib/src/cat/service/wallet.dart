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
    final totalPaymentAmount = payments.fold(0, (int previousValue, payment) => previousValue + payment.amount);

    final catCoins = List<CatCoin>.from(catCoinsInput);

    final distinctAssetIds = catCoins.map((c) => c.assetId).toSet();
    if(distinctAssetIds.length != 1) {
      throw MixedAssetIdsException(distinctAssetIds);
    }
    final totalCatCoinValue = catCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final change = totalCatCoinValue - totalPaymentAmount;

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    final spendBundlesToAggregate = <SpendBundle>[];

    final spendableCats = <SpendableCat>[];
    var first = true;
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVector(catCoin.puzzlehash);
      final coinPublicKey = coinWalletVector!.childPublicKey;

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
          // "ca" in bytes
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
        if (fee > 0) {
         spendBundlesToAggregate.add(_makeStandardSpendBundleForFee(
            fee: fee,
            standardCoins: standardCoinsForFee,
            keychain: keychain, 
            changePuzzlehash: changePuzzlehash
          ));
        }

        innerSolution = BaseWalletService.makeSolutionFromConditions(conditions);
      } else {
        innerSolution = BaseWalletService.makeSolutionFromConditions([primaryAssertCoinAnnouncement!]);
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

    final catSpendBundle = _makeCatSpendBundleFromSpendableCats(spendableCats, keychain);

    spendBundlesToAggregate.add(catSpendBundle);

    return SpendBundle.aggregate(spendBundlesToAggregate);
  }

  SpendBundle _makeCatSpendBundleFromSpendableCats(List<SpendableCat> spendableCats, WalletKeychain keychain) {
    SpendableCat.calculateAndAttachSubtotals(spendableCats);

    final spends = <CoinSpend>[];
    final signatures = <JacobianPoint>[];
    
    final n = spendableCats.length;
    for (var index = 0; index < n; index++) {
      final previousIndex = (index - 1) % n;
      final nextIndex = (index + 1) % n;

      final previousSpendableCat = spendableCats[previousIndex];
      final currentSpendableCat = spendableCats[index];
      final nextSpendableCat = spendableCats[nextIndex];

      final puzzleReveal = makeCatPuzzle(currentSpendableCat);

      final solution = makeCatSolution(
        previousSpendableCat: previousSpendableCat, 
        currentSpendableCat: currentSpendableCat, 
        nextSpendableCat: nextSpendableCat
      );

      final coinWalletVector = keychain.getWalletVector(currentSpendableCat.coin.puzzlehash);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;

      final solAndSig = createCoinsSpendAndSignature(solution, puzzleReveal, coinPrivateKey, currentSpendableCat.coin);

      spends.add(solAndSig.coinSpend);
      signatures.add(solAndSig.signature);
    }

    final catAggregateSignature = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: catAggregateSignature);
  }

  SpendBundle _makeStandardSpendBundleForFee({
    required int fee,
    required List<Coin> standardCoins,
    required WalletKeychain keychain,
    required Puzzlehash changePuzzlehash,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAsset = const [],
  }) {
    assert(standardCoins.isNotEmpty, 'If passing in a fee, you must also pass in standard coins to use for that fee.');
    final totalStandardCoinsValue = standardCoins.fold(0, (int previousValue, standardCoin) => previousValue + standardCoin.amount);
    assert(totalStandardCoinsValue >= fee, 'Total value of passed in standad coins is not enough to cover fee.');

    return standardWalletService.createSpendBundle(
      standardCoins, 
      0, 
      changePuzzlehash, 
      changePuzzlehash, 
      keychain, 
      fee: fee,
      coinAnnouncementsToAssert: coinAnnouncementsToAsset,
    );
  }

  // see chia/wallet/cc_wallet/cc_wallet.py: generate_unsigned_spendbundle
  static Program makeCatSolution({
    required SpendableCat previousSpendableCat, 
    required SpendableCat currentSpendableCat, 
    required SpendableCat nextSpendableCat,

    }) {
    assert(currentSpendableCat.subtotal != null, 'subtotal has not been attached to currentSpendableCat');
    return Program.list([
      currentSpendableCat.innerSolution, 
      currentSpendableCat.coin.lineageProof,
      Program.fromBytes(previousSpendableCat.coin.id.bytes),
      currentSpendableCat.coin.toProgram(),
      nextSpendableCat.makeStandardCoinProgram(),
      Program.fromInt(currentSpendableCat.subtotal!),
      Program.fromInt(0), // limitations_program_reveal: unused since we're not handling any cat discrepancy
    ]);
  }

  static Program makeCatPuzzle(SpendableCat spendableCat) {
    return catProgram.curry([
      Program.fromBytes(catProgram.hash()),
      Program.fromBytes(spendableCat.coin.assetId.bytes),
      spendableCat.innerPuzzle
    ]);
  }  
}
