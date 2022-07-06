import 'package:chia_crypto_utils/chia_crypto_utils.dart';

List<Coin> selectCoinsForAmount(List<Coin> coinsInput, int amount) {
  final coins = List<Coin>.from(coinsInput)
    ..sort(
      (a, b) => b.amount.compareTo(a.amount),
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
