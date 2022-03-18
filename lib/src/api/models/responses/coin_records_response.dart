import 'package:chia_utils/src/api/models/chia_models/chia_coin_record.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';

class CoinRecordsResponse extends ChiaBaseResponse {
  List<ChiaCoinRecord> coinRecords;

  CoinRecordsResponse({
    required this.coinRecords,
    required bool success,
    required String? error,
  }) : super(
    success: success,
    error: error,
  );

  factory CoinRecordsResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    final coinRecords = json['coin_records'] != null ?
        (json['coin_records'] as List)
            .map(
              (dynamic value) =>
                  ChiaCoinRecord.fromJson(value as Map<String, dynamic>),
            )
            .toList()
      :
        <ChiaCoinRecord>[];

    return CoinRecordsResponse(
      coinRecords: coinRecords,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}
