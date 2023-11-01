import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_cat1.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_cat2.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';

class Cat2PuzzleDriver extends CatPuzzleDriver {
  Cat2PuzzleDriver() : super(cat2Program);
}

class Cat1PuzzleDriver extends CatPuzzleDriver {
  Cat1PuzzleDriver() : super(cat1Program);
}

class CatPuzzleDriver implements PuzzleDriver {
  CatPuzzleDriver(this.catProgram);
  final Program catProgram;

  @override
  Puzzlehash getAssetId(Program fullPuzzle) {
    final arguments = fullPuzzle.uncurry().arguments;
    return Puzzlehash(arguments[1].atom);
  }

  @override
  Program getNewFullPuzzleForP2Puzzle(
    Program currentFullPuzzle,
    Program innerPuzzle,
  ) {
    return CatWalletService.makeCatPuzzleFromParts(
      catProgram: catProgram,
      innerPuzzle: innerPuzzle,
      assetId: getAssetId(currentFullPuzzle),
    );
  }

  // @override
  // Program? getInnerPuzzle(Program fullPuzzle) {
  //   final deconstructedProgram = fullPuzzle.uncurry();
  //   return deconstructedProgram.arguments[2];
  // }

  @override
  bool doesMatch(Program fullPuzzle) {
    return fullPuzzle.uncurry().mod == catProgram;
  }

  @override
  SpendType get type => catProgram == cat2Program ? SpendType.cat : SpendType.cat1;

  @override
  OfferedCoin makeOfferedCoinFromParentSpend(CoinPrototype coin, CoinSpend parentSpend) {
    if (type == SpendType.cat) {
      return OfferedCat2.fromOfferBundleParentSpend(coin, parentSpend);
    }
    return OfferedCat1.fromOfferBundleParentSpend(coin, parentSpend);
  }

  @override
  Program getP2Solution(CoinSpend coinSpend) {
    return coinSpend.solution.toList()[0];
  }

  @override
  Program getP2Puzzle(CoinSpend coinSpend) {
    final uncurriedResult = coinSpend.puzzleReveal.uncurry();
    final innerPuzzle = uncurriedResult.arguments[2];
    return innerPuzzle;
  }

  @override
  bool doesMatchUncurried(ModAndArguments uncurriedFullPuzzle, Program _) {
    return uncurriedFullPuzzle.mod == catProgram;
  }

  @override
  CoinPrototype getChildCoinForP2Payment(CoinSpend coinSpend, Payment p2Payment) {
    final outerPuzzlehash = WalletKeychain.makeOuterPuzzleHashForCatProgram(
      p2Payment.puzzlehash,
      getAssetId(coinSpend.puzzleReveal),
      catProgram,
    );

    return CoinPrototype(
      parentCoinInfo: coinSpend.coin.id,
      puzzlehash: outerPuzzlehash,
      amount: p2Payment.amount,
    );
  }
}
