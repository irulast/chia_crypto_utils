
import 'dart:convert';

import 'package:chia_utils/src/api/models/chia_models/chia_coin_record.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:http/http.dart';

class CoinRecordResponse extends ChiaBaseResponse {
  ChiaCoinRecord? coinRecord;

  CoinRecordResponse({
    required this.coinRecord,
    required bool success,
    required String? error,
    required int statusCode,
  }) : super(
    success: success,
    error: error,
    statusCode: statusCode,
  );

  factory CoinRecordResponse.fromHttpResponse(Response response) {
    final chiaBaseResponse = ChiaBaseResponse.fromHttpResponse(response);
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    
    return CoinRecordResponse(
      coinRecord: 
        jsonBody['coin_record'] != null ?
            ChiaCoinRecord.fromJson(jsonBody['coin_record'] as Map<String, dynamic>)
          :
            null,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
      statusCode: chiaBaseResponse.statusCode,
    );
  }
}
