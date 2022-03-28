// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class Coin extends CoinPrototype {
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;

  const Coin({
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
    required Bytes parentCoinInfo,
    required Puzzlehash puzzlehash,
    required int amount,
  }) : super(
            puzzlehash: puzzlehash,
            amount: amount,
            parentCoinInfo: parentCoinInfo,
    );

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
