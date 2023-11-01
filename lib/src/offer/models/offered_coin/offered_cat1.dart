import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';

class OfferedCat1 implements OfferedCoin {
  OfferedCat1(this.coin, this.settlementProgram);

  factory OfferedCat1.fromOfferBundleParentSpend(CoinPrototype coin, CoinSpend parentSpend) {
    final deconstructedCatPuzzle = _catWalletService.matchCatPuzzle(parentSpend.puzzleReveal);
    if (deconstructedCatPuzzle == null) {
      throw InvalidCatException(message: 'invalid cat 1');
    }

    final matchingSettlementProgram = () {
      for (final settlementProgram in [settlementPaymentsProgram, settlementPaymentsProgramOld]) {
        if (_catWalletService
                .makeCatPuzzle(deconstructedCatPuzzle.assetId, settlementProgram)
                .hash() ==
            coin.puzzlehash) {
          return settlementProgram;
        }
      }
      throw Exception('no matching settlement program');
    }();

    return OfferedCat1(
      CatCoin.fromParentSpend(parentCoinSpend: parentSpend, coin: coin),
      matchingSettlementProgram,
    );
  }

  @override
  final CatCoin coin;

  @override
  final Program settlementProgram;

  @override
  CoinSpend toOfferSpend(List<Program> innerSolutions) {
    final spendableCat = SpendableCat(
      coin: coin,
      innerPuzzle: settlementProgram,
      innerSolution: Program.list(innerSolutions),
    );

    final solution = _catWalletService
        .makeUnsignedSpendBundleForSpendableCats([spendableCat])
        .coinSpends[0]
        .solution;

    return CoinSpend(
      coin: coin,
      puzzleReveal: _catWalletService.makeCatPuzzle(coin.assetId, settlementProgram),
      solution: solution,
    );
  }

  @override
  SpendType get type => SpendType.cat1;

  static CatWalletService get _catWalletService => CatWalletService.fromCatProgram(cat1Program);

  @override
  Bytes get assetId => coin.assetId;

  @override
  Future<Puzzlehash> get p2Puzzlehash => coin.getP2Puzzlehash();

  @override
  Puzzlehash get p2PuzzlehashSync => coin.getP2PuzzlehashSync();
}
