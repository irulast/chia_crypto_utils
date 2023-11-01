import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class UnsupportedCoinException implements Exception {
  UnsupportedCoinException(this.coinSpend);
  final CoinSpend coinSpend;

  @override
  String toString() => 'Unsupported coin in offer: ${coinSpend.coin}';
}
