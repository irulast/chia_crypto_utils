// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class CoinRecordsWithCoinSpendsResponse extends ChiaBaseResponse {
  const CoinRecordsWithCoinSpendsResponse({
    required this.coinRecords,
    required this.lastId,
    required this.totalCoinCount,
    required super.success,
    required super.error,
  });

  factory CoinRecordsWithCoinSpendsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    final coinRecords = json['coin_records'] != null
        ? (json['coin_records'] as List)
            .map(
              (dynamic value) => ChiaCoinRecordWithCoinSpend.fromJson(
                value as Map<String, dynamic>,
              ),
            )
            .toList()
        : <ChiaCoinRecordWithCoinSpend>[];

    final lastIdSerialized = json['last_id'] as String?;

    final lastId =
        (lastIdSerialized != null) ? Bytes.fromHex(lastIdSerialized) : null;

    return CoinRecordsWithCoinSpendsResponse(
      coinRecords: coinRecords,
      lastId: lastId,
      totalCoinCount: json['total_coin_count'] as int?,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
  final List<ChiaCoinRecordWithCoinSpend> coinRecords;
  final Bytes? lastId;
  final int? totalCoinCount;

  @override
  String toString() =>
      'CoinRecordsResponse(coinRecords: $coinRecords, success: $success, error: $error)';
}
