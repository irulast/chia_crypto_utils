import 'dart:convert';

import 'package:http/http.dart';

class ChiaBaseResponse {
  String? error;
  bool success;
  int statusCode;

  ChiaBaseResponse({
    required this.error, 
    required this.success,
    required this.statusCode,
  });

  factory ChiaBaseResponse.fromHttpResponse(Response response) {
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

    return ChiaBaseResponse(
      error: jsonBody['error'] as String,
      success: jsonBody['success'] as bool,
      statusCode: response.statusCode
    );
  }
}
