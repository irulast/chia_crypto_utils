import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/cat/puzzles/cat.clvm.hex.dart';
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
      Puzzlehash? originId,
    }
    ) {
    final spendBundlesToAggregate = <SpendBundle>[];
    if (fee > 0) {
      assert(standardCoinsForFee.isNotEmpty, 'If passing in a fee, you must also pass in standard coins to use for that fee.');
      final totalStandardCoinsValue = standardCoinsForFee.fold(0, (int previousValue, standardCoin) => previousValue + standardCoin.amount);
      assert(totalStandardCoinsValue >= fee, 'Total value of passed in standad coins is not enough to cover fee.');

      final spendBundleForFee = standardWalletService.createSpendBundle(standardCoinsForFee, 0, Address.fromPuzzlehash(changePuzzlehash, blockchainNetwork.addressPrefix), changePuzzlehash, keychain);
      spendBundlesToAggregate.add(spendBundleForFee);
    }

    final totalPaymentAmount = payments.fold(0, (int previousValue, payment) => previousValue + payment.amount);

    final catCoins = List<CatCoin>.from(catCoinsInput);

    final distinctAssetIds = catCoins.map((c) => c.assetId).toSet();
    if(distinctAssetIds.length != 1) {
      throw MixedAssetIdsException(distinctAssetIds);
    }
    final totalCatCoinValue = catCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final change = totalCatCoinValue - totalPaymentAmount - fee;

    final signatures = <JacobianPoint>[];
    final spends = <CoinSpend>[];

    // returns -1 if originId is given but is not in coins
    final originIndex = originId == null ? 0 : catCoins.indexWhere((coin) => coin.id.hex == originId.hex);

    if (originIndex == -1) {
      throw Exception('Origin id not in coins');
    }

    final originCoin = catCoins.removeAt(originIndex);

    // create coin spend for origin coin
    final originCoinWalletVector = keychain.getWalletVector(originCoin.puzzlehash);
    final originCoinPrivateKey = originCoinWalletVector!.childPrivateKey;
    final originCoinPublicKey = originCoinPrivateKey.getG1();

    final conditions = <Condition>[];
    final createdCoins = <CoinPrototype>[];

    for (final payment in payments) {
      final sendCreateCoinCondition = payment.toCreateCoinCondition();
      conditions.add(sendCreateCoinCondition);
      createdCoins.add(
        CoinPrototype(
          parentCoinInfo: originCoin.id,
          puzzlehash: payment.puzzlehash,
          amount: payment.amount,
        ),
      );
    } 

    if (change > 0) {
      conditions.add(CreateCoinCondition(changePuzzlehash, change));
      createdCoins.add(
        CoinPrototype(
          parentCoinInfo: originCoin.id,
          puzzlehash: changePuzzlehash,
          amount: change,
        ),
      );
    }

    final existingCoinsMessage = catCoins.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id) + originCoin.id;
    final message = existingCoinsMessage.sha256Hash();
    conditions.add(CreateCoinAnnouncementCondition(message));

    final originCoinInnerSolution = BaseWalletService.makeSolutionFromConditions(conditions);
    final originCoinInnerPuzzle = getPuzzleFromPk(originCoinPublicKey);

    final originCatPuzzle = makeCatPuzzle(originCoinInnerPuzzle, originCoin.assetId);
    final originCatSolution = makeCatSolution(originCoinInnerPuzzle, originCoinInnerSolution, originCoin);

    final coinSpendAndSig = createCoinsSpendAndSignature(originCatSolution, originCatPuzzle, originCoinPrivateKey, originCoin);
    spends.add(coinSpendAndSig.coinSpend);
    signatures.add(coinSpendAndSig.signature);

    final primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition.fromParts(originCoin.id, message, morphBytes: Puzzlehash([202]));

    // do the rest of the coins
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVector(catCoin.puzzlehash);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;
      final coinPublicKey = coinPrivateKey.getG1();

      final innerSolution = BaseWalletService.makeSolutionFromConditions([primaryAssertCoinAnnouncement]);
      final innerPuzzle = getPuzzleFromPk(coinPublicKey);

      final catPuzzle = makeCatPuzzle(innerPuzzle, catCoin.assetId);
      final catSolution = makeCatSolution(innerPuzzle, innerSolution, catCoin);

      final coinSpendAndSig = createCoinsSpendAndSignature(catSolution, catPuzzle, coinPrivateKey, catCoin);
      spends.add(coinSpendAndSig.coinSpend);
      signatures.add(coinSpendAndSig.signature);
    } 

    final catAggregateSignature = AugSchemeMPL.aggregate(signatures);
    final catSpendBundle = SpendBundle(coinSpends: spends, aggregatedSignature: catAggregateSignature);

    spendBundlesToAggregate.add(catSpendBundle);

    return SpendBundle.aggregate(spendBundlesToAggregate);
  }

  // see chia/wallet/cc_wallet/cc_wallet.py: generate_unsigned_spendbundle
  Program makeCatSolution(Program innerPuzzle, Program innerSolution, CatCoin catCoin) {
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

  Program makeCatPuzzle(Program innerPuzzle, Puzzlehash assetId) {
    return catProgram.curry([
      Program.fromBytes(catProgram.hash()),
      Program.fromBytes(assetId.bytes),
      innerPuzzle
    ]);
  }
}
