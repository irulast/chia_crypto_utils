import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/models/coin_spend.dart';
import 'package:hex/hex.dart';

class SpendBundle {
  List<CoinSpend> coinSpends;
  JacobianPoint aggregatedSignature;

  SpendBundle({
    required this.coinSpends,
    required this.aggregatedSignature,
  });

  SpendBundle.fromJson(Map<String, dynamic> json)
    : coinSpends = (json['coin_spends'] as List)
            .map((value) => CoinSpend.fromJson(value))
            .toList(), 
      aggregatedSignature = JacobianPoint.fromBytesG1(const HexDecoder().convert(json['aggregated_signature']));

  Map<String, dynamic> toJson() => {
    'coin_spends': coinSpends.map((e) => e.toJson()).toList(),
    'aggregated_signature': aggregatedSignature.toHex(),
  };
}