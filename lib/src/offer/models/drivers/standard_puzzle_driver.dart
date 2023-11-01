import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_standard_coin.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';

class StandardPuzzleDriver implements PuzzleDriver {
  StandardPuzzleDriver();

  @override
  Puzzlehash? getAssetId(Program fullPuzzle) {
    return null;
  }

  @override
  Program getNewFullPuzzleForP2Puzzle(
    Program currentFullPuzzle,
    Program innerPuzzle,
  ) {
    return innerPuzzle;
  }

  @override
  bool doesMatch(Program fullPuzzle) {
    final mod = fullPuzzle.uncurry().mod;
    return mod == p2DelegatedPuzzleOrHiddenPuzzleProgram ||
        // no curried args in settlement programs
        fullPuzzle == settlementPaymentsProgram ||
        fullPuzzle == settlementPaymentsProgramOld ||
        mod == curriedConditionProgram;
  }

  @override
  SpendType get type => SpendType.standard;

  @override
  OfferedCoin makeOfferedCoinFromParentSpend(
      CoinPrototype coin, CoinSpend parentSpend) {
    return OfferedStandardCoin.fromOfferBundleCoin(coin);
  }

  @override
  Program getP2Solution(CoinSpend coinSpend) {
    return coinSpend.solution;
  }

  @override
  Program getP2Puzzle(CoinSpend coinSpend) {
    return coinSpend.puzzleReveal;
  }

  @override
  bool doesMatchUncurried(
      ModAndArguments uncurriedFullPuzzle, Program fullPuzzle) {
    final mod = uncurriedFullPuzzle.mod;
    return mod == p2DelegatedPuzzleOrHiddenPuzzleProgram ||
        // no curried args in settlement programs
        fullPuzzle == settlementPaymentsProgram ||
        fullPuzzle == settlementPaymentsProgramOld ||
        mod == curriedConditionProgram;
  }

  @override
  CoinPrototype getChildCoinForP2Payment(
      CoinSpend coinSpend, Payment p2Payment) {
    return CoinPrototype(
      parentCoinInfo: coinSpend.coin.id,
      puzzlehash: p2Payment.puzzlehash,
      amount: p2Payment.amount,
    );
  }
}
