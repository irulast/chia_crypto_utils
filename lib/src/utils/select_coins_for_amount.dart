import 'package:chia_crypto_utils/chia_crypto_utils.dart';

typedef CoinSelector = List<Coin> Function(List<Coin> coinsInput, int amount);

List<Coin> selectCoinsForAmount(List<Coin> coinsInput, int amount) {
  final coins = List<Coin>.from(coinsInput)
    ..sort(
      (a, b) => a.amount.compareTo(b.amount),
    );
  var totalCoinValue = 0;

  final selectedCoins = <Coin>[];

  for (final coin in coins) {
    if (totalCoinValue >= amount) {
      break;
    }
    selectedCoins.add(coin);
    totalCoinValue += coin.amount;
  }

  if (totalCoinValue < amount) {
    throw ArgumentError('Total input coin value < desired amount');
  }

  return selectedCoins;
}
