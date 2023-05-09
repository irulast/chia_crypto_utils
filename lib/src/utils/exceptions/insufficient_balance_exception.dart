class InsufficientBalanceException implements Exception {
  InsufficientBalanceException({
    required this.requiredBalance,
    required this.currentBalance,
  });

  final int requiredBalance;
  final int currentBalance;

  @override
  String toString() {
    return 'Insufficient balance : $currentBalance < $requiredBalance';
  }
}

class MaxCoinsExceededException implements Exception {
  MaxCoinsExceededException(this.maxNumberOfCoins);

  final int maxNumberOfCoins;

  @override
  String toString() {
    return 'Exceeded max number of coins allowed: $maxNumberOfCoins';
  }
}
