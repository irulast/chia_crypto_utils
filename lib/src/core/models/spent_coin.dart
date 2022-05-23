import 'package:chia_utils/chia_crypto_utils.dart';

class SpentCoin extends Coin {
  const SpentCoin({
    required int confirmedBlockIndex,
    required int spentBlockIndex,
    required bool coinbase,
    required int timestamp,
    required Bytes parentCoinInfo,
    required Puzzlehash puzzlehash,
    required int amount,
    required Program puzzleReveal,
    required Program solution,
  })  : _puzzleReveal = puzzleReveal,
        _solution = solution,
        super(
          confirmedBlockIndex: confirmedBlockIndex,
          spentBlockIndex: spentBlockIndex,
          coinbase: coinbase,
          timestamp: timestamp,
          puzzlehash: puzzlehash,
          amount: amount,
          parentCoinInfo: parentCoinInfo,
        );

  factory SpentCoin.fromCoinSpend(Coin coin, CoinSpend coinSpend) {
    if (coin.id != coinSpend.coin.id) {
      ArgumentError('Coin spend is not for this coin');
    }
    return SpentCoin(
      confirmedBlockIndex: coin.confirmedBlockIndex,
      spentBlockIndex: coin.spentBlockIndex,
      coinbase: coin.coinbase,
      timestamp: coin.timestamp,
      parentCoinInfo: coin.parentCoinInfo,
      puzzlehash: coin.puzzlehash,
      amount: coin.amount,
      puzzleReveal: coinSpend.puzzleReveal,
      solution: coinSpend.solution,
    );
  }

  final Program _puzzleReveal;
  final Program _solution;

  CoinSpend get coinSpend => CoinSpend(
        coin: this,
        puzzleReveal: _puzzleReveal,
        solution: _solution,
      );
}
