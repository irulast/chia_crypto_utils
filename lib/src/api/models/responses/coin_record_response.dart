import 'package:chia_utils/src/api/models/chia_models/chia_coin_record.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:meta/meta.dart';

@immutable
class CoinRecordResponse extends ChiaBaseResponse {
  final ChiaCoinRecord? coinRecord;

  const CoinRecordResponse({
    required this.coinRecord,
    required bool success,
    required String? error,
  }) : super(
    success: success,
    error: error,
  );

  factory CoinRecordResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return CoinRecordResponse(
      coinRecord: 
        json['coin_record'] != null ?
            ChiaCoinRecord.fromJson(json['coin_record'] as Map<String, dynamic>)
          :
            null,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}
