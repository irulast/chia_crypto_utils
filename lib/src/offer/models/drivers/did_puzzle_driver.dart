import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/did/models/uncurried_did_puzzle.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';

class DidPuzzleDriver implements PuzzleDriver {
  @override
  bool doesMatch(Program fullPuzzle) {
    return UncurriedDidPuzzle.maybeFromProgram(fullPuzzle) != null;
  }

  @override
  bool doesMatchUncurried(ModAndArguments fullPuzzle, Program _) {
    return UncurriedDidPuzzle.maybeFromUncurriedProgram(fullPuzzle) != null;
  }

  @override
  Puzzlehash? getAssetId(Program fullPuzzle) {
    return Puzzlehash.maybe(UncurriedDidPuzzle.maybeFromProgram(fullPuzzle)?.did);
  }

  @override
  Program getNewFullPuzzleForP2Puzzle(Program currentFullPuzzle, Program p2Puzzle) {
    // TODO(nvjoshi): implement getNewFullPuzzleForP2Puzzle
    throw UnimplementedError();
  }

  @override
  Program getP2Puzzle(CoinSpend coinSpend) {
    return UncurriedDidPuzzle.fromProgram(coinSpend.puzzleReveal).innerPuzzle.p2Puzzle;
  }

  @override
  Program getP2Solution(CoinSpend coinSpend) {
    // TODO(nvjoshi): implement getP2Solution
    throw UnimplementedError();
  }

  @override
  OfferedCoin makeOfferedCoinFromParentSpend(CoinPrototype coin, CoinSpend parentSpend) {
    // TODO(nvjoshi): implement makeOfferedCoinFromParentSpend
    throw UnimplementedError();
  }

  @override
  CoinPrototype getChildCoinForP2Payment(CoinSpend coinSpend, Payment p2Payment) {
    return getSingletonChildFromCoinSpend(coinSpend);
  }

  @override
  SpendType get type => SpendType.did;
}
