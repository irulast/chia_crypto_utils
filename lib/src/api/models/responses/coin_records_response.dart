import 'dart:convert';

import 'package:chia_utils/src/api/models/chia_models/chia_coin_record.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:http/http.dart';

class CoinRecordsResponse extends ChiaBaseResponse {
  List<ChiaCoinRecord>? coinRecords;

  CoinRecordsResponse({
    required this.coinRecords,
    required bool success,
    required String? error,
    required int statusCode,
  }) : super(
    success: success,
    error: error,
    statusCode: statusCode,
  );

  factory CoinRecordsResponse.fromHttpResponse(Response response) {
    final chiaBaseResponse = ChiaBaseResponse.fromHttpResponse(response);
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    
    final coinRecords = jsonBody['coin_records'] != null ?
        (jsonBody['coin_records'] as List)
            .map(
              (dynamic value) =>
                  ChiaCoinRecord.fromJson(value as Map<String, dynamic>),
            )
            .toList()
      :
        null;

    return CoinRecordsResponse(
      coinRecords: coinRecords,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
      statusCode: chiaBaseResponse.statusCode,
    );
  }
}
