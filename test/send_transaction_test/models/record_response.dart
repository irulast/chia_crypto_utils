import 'coin_response.dart';

class RecordResponse {
  RecordResponse({
    required this.coin,
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
  });

  RecordResponse.fromJson(Map<String, dynamic> json)
      : coin = CoinResponse.fromJson(json['coin'] as Map<String, dynamic>),
        confirmedBlockIndex = json['confirmed_block_index'] as int,
        spentBlockIndex = json['spent_block_index'] as int,
        coinbase = json['coinbase'] as bool,
        timestamp = json['timestamp'] as int;

  CoinResponse coin;
  int confirmedBlockIndex;
  int spentBlockIndex;
  bool coinbase;
  int timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin': coin.toJson(),
        'confirmed_block_index': confirmedBlockIndex,
        'spent_block_index': spentBlockIndex,
        'coinbase': coinbase,
        'timestamp': timestamp
      };
}
