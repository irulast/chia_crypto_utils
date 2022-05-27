import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class ChiaCoinRecord {
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;
  final CoinPrototype coin;

  const ChiaCoinRecord({
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
    required this.coin,
  });

  factory ChiaCoinRecord.fromJson(Map<String, dynamic> json) {
    return ChiaCoinRecord(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>),
    );
  }

  Coin toCoin() {
    return Coin(
      confirmedBlockIndex: confirmedBlockIndex,
      spentBlockIndex: spentBlockIndex,
      coinbase: coinbase,
      timestamp: timestamp,
      parentCoinInfo: coin.parentCoinInfo,
      puzzlehash: coin.puzzlehash,
      amount: coin.amount,
    );
  }

  @override
  String toString() => toCoin().toString();
}
