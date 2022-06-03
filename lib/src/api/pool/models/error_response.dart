import 'package:chia_crypto_utils/src/api/pool/models/pool_error_response_code.dart';

class ErrorResponse {
  const ErrorResponse(this.responseCode, this.message);
  ErrorResponse.fromJson(Map<String, dynamic> json)
      : responseCode = PoolErrorResponseCode.fromCode(json[errorCodeKey] as int),
        message = json[errorMessageKey] as String;
        
  final PoolErrorResponseCode responseCode;
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
