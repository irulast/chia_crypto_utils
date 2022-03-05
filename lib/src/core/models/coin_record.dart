import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/models/coin.dart';

// TODO: refactor to replace Coin, rename to Coin
class CoinRecord {
  CoinRecord({
    required this.parentCoinInfo,
    required this.puzzlehash,
    required this.amount,
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
  });

  // coin fields
  Puzzlehash parentCoinInfo;
  Puzzlehash puzzlehash;
  int amount;

  // coin_record fields
  int confirmedBlockIndex;
  int spentBlockIndex;
  bool coinbase;
  int timestamp;

  factory CoinRecord.fromJson(Map<String, dynamic> json) {
    : coin = Coin.fromJson(json['coin'] as Map<String, dynamic>),
      confirmedBlockIndex = json['confirmed_block_index'] as int,
      spentBlockIndex = json['spent_block_index'] as int,
      coinbase = json['coinbase'] as bool,
      timestamp = json['timestamp'] as int;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
      'coin': coin.toJson(),
      'confirmed_block_index': confirmedBlockIndex,
      'spent_block_index': spentBlockIndex,
      'coinbase': coinbase,
      'timestamp': timestamp
  };
}
