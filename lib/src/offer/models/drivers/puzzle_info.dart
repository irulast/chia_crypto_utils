import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';

class PuzzleInfo {
  PuzzleInfo(this.driver, this.fullPuzzle);
  static PuzzleInfo? match(Program fullPuzzle) {
    final matchingDrivers = drivers.where((e) => e.doesMatch(fullPuzzle));
    if (matchingDrivers.isEmpty) {
      return null;
    }
    return PuzzleInfo(
      matchingDrivers.single,
      fullPuzzle,
    );
  }

  final Program fullPuzzle;
  final PuzzleDriver driver;

  Puzzlehash? get assetId => driver.getAssetId(fullPuzzle);

  Program getNewFullPuzzleForP2Puzzle(Program p2Puzzle) =>
      driver.getNewFullPuzzleForP2Puzzle(fullPuzzle, p2Puzzle);

  SpendType get type => driver.type;

  OfferedCoin? makeOfferedCoinFromParentSpend(
    CoinPrototype coin,
    CoinSpend parentSpend,
  ) {
    try {
      return driver.makeOfferedCoinFromParentSpend(
        coin,
        parentSpend,
      );
    } catch (e) {
      return null;
    }
  }
}
