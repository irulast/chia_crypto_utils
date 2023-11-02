import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class ChiaCoinRecordWithCoinSpend extends ChiaCoinRecord {
  const ChiaCoinRecordWithCoinSpend({
    required super.confirmedBlockIndex,
    required super.spentBlockIndex,
    required super.coinbase,
    required super.timestamp,
    required super.coin,
    this.coinSpend,
    this.parentSpend,
  });

  factory ChiaCoinRecordWithCoinSpend.fromJson(Map<String, dynamic> json) {
    if (json['spent_block_index'] as int > 0 && json['coin_spend'] == null) {
      LoggingContext().error('incorrect spent record json: $json');
    }
    return ChiaCoinRecordWithCoinSpend(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>),
      coinSpend: (json['coin_spend'] == null)
          ? null
          : CoinSpend.fromJson(json['coin_spend'] as Map<String, dynamic>),
      parentSpend: (json['parent_coin_spend'] == null)
          ? null
          : CoinSpend.fromJson(
              json['parent_coin_spend'] as Map<String, dynamic>,
            ),
    );
  }
  final CoinSpend? coinSpend;
  final CoinSpend? parentSpend;

  SpentCoin toSpentCoin() {
    return SpentCoin.fromCoinSpend(toCoin(), coinSpend!);
  }

  CoinWithParentSpend toCoinWithParentSpend() {
    return CoinWithParentSpend.fromCoin(toCoin(), parentSpend);
  }
}
