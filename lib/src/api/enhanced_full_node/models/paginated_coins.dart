import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PaginatedCoins with ToJsonMixin {
  PaginatedCoins(this.spent, this.unspent, this.lastId, this.totalCoinCount);
  factory PaginatedCoins.fromJson(Map<String, dynamic> json) {
    final spentCoins = (json['spent_coins'] as List)
        .map(
          (dynamic value) => SpentCoin.fromJson(value as Map<String, dynamic>),
        )
        .toList();

    final unspentCoins = (json['unspent_coins'] as List)
        .map(
          (dynamic value) =>
              CoinWithParentSpend.fromJson(value as Map<String, dynamic>),
        )
        .toList();

    final lastIdSerialized = json['last_id'] as String?;

    final lastId =
        (lastIdSerialized != null) ? Bytes.fromHex(lastIdSerialized) : null;

    final totalCoinCount = json['total_coin_count'] as int?;
    return PaginatedCoins(spentCoins, unspentCoins, lastId, totalCoinCount);
  }

  final List<SpentCoin> spent;
  final List<CoinWithParentSpend> unspent;
  final Bytes? lastId;
  final int? totalCoinCount;

  int get length => spent.length + unspent.length;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'spent_coins': spent.map((c) => c.toJson()).toList(),
        'unspent_coins': unspent.map((c) => c.toFullJson()).toList(),
        'last_id': lastId?.toHex(),
        'total_coin_count': totalCoinCount,
      };
}
