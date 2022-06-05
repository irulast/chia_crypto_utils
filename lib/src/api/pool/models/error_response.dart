import 'package:chia_crypto_utils/src/api/pool/models/pool_error_response_code.dart';

class PoolErrorResponse {
  const PoolErrorResponse(this.responseCode, this.message);
  PoolErrorResponse.fromJson(Map<String, dynamic> json)
      : responseCode = codeToPoolErrorResponse(json[errorCodeKey] as int),
        message = json[errorMessageKey] as String;

  final PoolErrorState responseCode;
  final String message;

  static bool isErrorResponse(Map<String, dynamic> body) {
    if (body[errorCodeKey] != null) {
      return true;
    }
    return false;
  }

  static String errorCodeKey = 'error_code';
  static String errorMessageKey = 'error_message';
}
