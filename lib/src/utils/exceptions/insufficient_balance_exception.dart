import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class InsufficientBalanceException implements Exception {
  InsufficientBalanceException({
    required this.requiredBalance,
    required this.currentBalance,
  });

  final int requiredBalance;
  final int currentBalance;
}

class InsufficientStandardBalanceException
    extends InsufficientBalanceException {
  InsufficientStandardBalanceException({
    required super.requiredBalance,
    required super.currentBalance,
  });
  @override
  String toString() {
    return 'Insufficient xch balance : $currentBalance < $requiredBalance';
  }
}

class InsufficientCatBalanceException extends InsufficientBalanceException {
  InsufficientCatBalanceException({
    required super.requiredBalance,
    required super.currentBalance,
    required this.assetId,
  });
  final Puzzlehash assetId;

  @override
  String toString() {
    return 'Insufficient Cat balance : $currentBalance < $requiredBalance';
  }
}

class InsufficientNftBalanceException extends InsufficientBalanceException {
  InsufficientNftBalanceException(this.launcherId)
      : super(currentBalance: 0, requiredBalance: 1);
  final Bytes launcherId;

  @override
  String toString() {
    return 'No owned NFT for launcher id $launcherId';
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
