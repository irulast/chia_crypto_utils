// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/api/full_node/models/chia_models/chia_coin_record.dart';
import 'package:chia_crypto_utils/src/api/full_node/models/responses/chia_base_response.dart';
import 'package:meta/meta.dart';

@immutable
class CoinRecordsResponse extends ChiaBaseResponse {
  final List<ChiaCoinRecord> coinRecords;

  const CoinRecordsResponse({
    required this.coinRecords,
    required bool success,
    required String? error,
  }) : super(
          success: success,
          error: error,
        );

  factory CoinRecordsResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    final coinRecords = json['coin_records'] != null
        ? (json['coin_records'] as List)
            .map(
              (dynamic value) => ChiaCoinRecord.fromJson(value as Map<String, dynamic>),
            )
            .toList()
        : <ChiaCoinRecord>[];

    return CoinRecordsResponse(
      coinRecords: coinRecords,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }

  @override
  String toString() =>
      'CoinRecordsResponse(coinRecords: $coinRecords, success: $success, error: $error)';
}
