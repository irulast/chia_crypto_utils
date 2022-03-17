import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:http/http.dart';

class CoinSpendResponse extends ChiaBaseResponse {
  CoinSpend? coinSpend;

  CoinSpendResponse({
    required this.coinSpend,
    required bool success,
    required String? error,
    required int statusCode,
  }) : super(
    success: success,
    error: error,
    statusCode: statusCode
  );

  factory CoinSpendResponse.fromHttpResponse(Response response) {
    final chiaBaseResponse = ChiaBaseResponse.fromHttpResponse(response);
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

    return CoinSpendResponse(
      coinSpend: 
        jsonBody['coin_solution'] != null ?
            CoinSpend.fromJson(jsonBody['coin_solution'] as Map<String, dynamic>)
          :
            null
          ,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
      statusCode: response.statusCode,
    );
  }
}
