// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class CoinSpendResponse extends ChiaBaseResponse {
  const CoinSpendResponse({
    required this.coinSpend,
    required super.success,
    required super.error,
  });

  factory CoinSpendResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return CoinSpendResponse(
      coinSpend: json['coin_solution'] != null
          ? CoinSpend.fromJson(json['coin_solution'] as Map<String, dynamic>)
          : null,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
  final CoinSpend? coinSpend;

  @override
  String toString() => 'CoinSpendResponse(coinSpend: $coinSpend, success: $success, error: $error)';
}
