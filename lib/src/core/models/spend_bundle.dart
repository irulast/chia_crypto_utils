import 'package:chia_utils/chia_crypto_utils.dart';

class SpendBundle {
  List<CoinSpend> coinSpends;
  JacobianPoint aggregatedSignature;

  SpendBundle({
    required this.coinSpends,
    required this.aggregatedSignature,
  });

  Map<String, dynamic> toJson() => <String, dynamic> {
      'coin_spends': coinSpends.map((e) => e.toJson()).toList(),
      'aggregated_signature': aggregatedSignature.toHex(),
    };
}
