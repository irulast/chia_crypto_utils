// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:chia_utils/src/core/models/coin_prototype.dart';
import 'package:chia_utils/src/core/models/coin_spend.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';


// ignore: must_be_immutable
class Coin extends CoinPrototype {
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;

  CoinSpend? parentCoinSpend;

  Coin({
    this.parentCoinSpend,
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
    required Puzzlehash parentCoinInfo,
    required Puzzlehash puzzlehash,
    required int amount,
  }) : super(
            puzzlehash: puzzlehash,
            amount: amount,
            parentCoinInfo: parentCoinInfo);

  factory Coin.fromChiaCoinRecordJson(Map<String, dynamic> json) {
    final coinPrototype = CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>);
    return Coin(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }
}
