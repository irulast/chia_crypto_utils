// ignore_for_file: lines_longer_than_80_chars

class InsufficientCoinsException implements Exception {
  InsufficientCoinsException({
    required this.attemptedSpendAmount,
    required this.coinTotalValue,
  });

  final int coinTotalValue;
  final int attemptedSpendAmount;
  @override
  String toString() {
    return 'Total coins value doesnt cover attempted spend amount. $coinTotalValue < $attemptedSpendAmount';
  }
}
