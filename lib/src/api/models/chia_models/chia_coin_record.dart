import 'package:chia_utils/chia_crypto_utils.dart';

class ChiaCoinRecord {
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;
  final CoinPrototype coin;

  ChiaCoinRecord({
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
}