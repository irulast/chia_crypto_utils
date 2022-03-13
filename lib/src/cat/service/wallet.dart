import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/payment.dart';
import 'package:chia_utils/src/core/service/wallet.dart';

class CatWalletService extends WalletService {
  late StandardWalletService standardWalletService;
  // TODO: this should be loaded from a file
  // ignore: non_constant_identifier_names
  final CC_MOD = Program.parse('(a (q 2 94 (c 2 (c (c 5 (c (sha256 44 5) (c 11 ()))) (c (a 23 47) (c 95 (c (a 46 (c 2 (c 23 ()))) (c (sha256 639 1407 2943) (c -65 (c 383 (c 767 (c 1535 (c 3071 ())))))))))))) (c (q (((-54 . 61) 70 2 . 51) (60 . 4) 1 1 . -53) ((a 2 (i 5 (q 2 50 (c 2 (c 13 (c (sha256 34 (sha256 44 52) (sha256 34 (sha256 34 (sha256 44 92) 9) (sha256 34 11 (sha256 44 ())))) ())))) (q . 11)) 1) (a (i 11 (q 2 (i (= (a 46 (c 2 (c 19 ()))) 2975) (q 2 38 (c 2 (c (a 19 (c 95 (c 23 (c 47 (c -65 (c 383 (c 27 ()))))))) (c 383 ())))) (q 8)) 1) (q 2 (i 23 (q 2 (i (not -65) (q . 383) (q 8)) 1) (q 8)) 1)) 1) (c (c 5 39) (c (+ 11 87) 119)) 2 (i 5 (q 2 (i (= (a (i (= 17 120) (q . 89) ()) 1) (q . -113)) (q 2 122 (c 2 (c 13 (c 11 (c (c -71 377) ()))))) (q 2 90 (c 2 (c (a (i (= 17 120) (q 4 120 (c (a 54 (c 2 (c 19 (c 41 (c (sha256 44 91) (c 43 ())))))) 57)) (q 2 (i (= 17 36) (q 4 36 (c (sha256 32 41) 57)) (q . 9)) 1)) 1) (c (a (i (= 17 120) (q . 89) ()) 1) (c (a 122 (c 2 (c 13 (c 11 (c 23 ()))))) ())))))) 1) (q 4 () (c () 23))) 1) ((a (i 5 (q 4 9 (a 38 (c 2 (c 13 (c 11 ()))))) (q . 11)) 1) 11 34 (sha256 44 88) (sha256 34 (sha256 34 (sha256 44 92) 5) (sha256 34 (a 50 (c 2 (c 7 (c (sha256 44 44) ())))) (sha256 44 ())))) (a (i (l 5) (q 11 (q . 2) (a 46 (c 2 (c 9 ()))) (a 46 (c 2 (c 13 ())))) (q 11 44 5)) 1) (c (c 40 (c 95 ())) (a 126 (c 2 (c (c (c 47 5) (c 95 383)) (c (a 122 (c 2 (c 11 (c 5 (q ()))))) (c 23 (c -65 (c 383 (c (sha256 1279 (a 54 (c 2 (c 9 (c 2815 (c (sha256 44 45) (c 21 ())))))) 5887) (c 1535 (c 3071 ()))))))))))) 2 42 (c 2 (c 95 (c 59 (c (a (i 23 (q 9 45 (sha256 39 (a 54 (c 2 (c 41 (c 87 (c (sha256 44 -71) (c 89 ())))))) -73)) ()) 1) (c 23 (c 5 (c 767 (c (c (c 36 (c (sha256 124 47 383) ())) (c (c 48 (c (sha256 -65 (sha256 124 21 (+ 383 (- 735 43) 767))) ())) 19)) ()))))))))) 1))');
  
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

    // TODO: only CATs with the same TAIL can be summed? This may result in undefined behavior with mixed kinds
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
    final originCoinWalletVector = keychain.getWalletVectorByOuterHash(originCoin.puzzlehash);
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
    final createdCoinsMessage = createdCoins.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id);
    final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
    conditions.add(CreateCoinAnnouncementCondition(message));

    final originCoinInnerSolution = WalletService.makeSolutionFromConditions(conditions);
    final originCoinInnerPuzzle = getPuzzleFromPk(originCoinPublicKey);

    final catPuzzle = makeCatPuzzle(originCoinInnerPuzzle, originCoin.assetId);
    final catSolution = makeCatSolution(originCoinInnerPuzzle, originCoinInnerSolution, originCoin);

    final coinSpendAndSig = createCoinsSpendAndSignature(catSolution, catPuzzle, originCoinPrivateKey, originCoin);
    spends.add(coinSpendAndSig.coinSpend);
    signatures.add(coinSpendAndSig.signature);

    final primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition.fromParts(originCoin.id, message);

    // do the rest of the coins
    for (final catCoin in catCoins) {
      final coinWalletVector = keychain.getWalletVectorByOuterHash(catCoin.puzzlehash);
      final coinPrivateKey = coinWalletVector!.childPrivateKey;
      final coinPublicKey = coinPrivateKey.getG1();

      final innerSolution = WalletService.makeSolutionFromConditions([primaryAssertCoinAnnouncement]);
      final innerPuzzle = getPuzzleFromPk(coinPublicKey);

      final catPuzzle = makeCatPuzzle(innerPuzzle, catCoin.assetId);
      final catSolution = makeCatSolution(innerPuzzle, innerSolution, catCoin);

      final coinSpendAndSig = createCoinsSpendAndSignature(catSolution, catPuzzle, originCoinPrivateKey, originCoin);
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
    return CC_MOD.curry([
      Program.fromBytes(CC_MOD.hash()),
      Program.fromBytes(assetId.bytes),
      innerPuzzle
    ]);
  }
}
