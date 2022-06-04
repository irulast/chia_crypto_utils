import 'package:chia_crypto_utils/src/api/pool/models/error_response.dart';

class PoolResponseException implements Exception {
  PoolResponseException(this.poolErrorResponse, this.poolUrl);
  final PoolErrorResponse poolErrorResponse;
  final String poolUrl;

  @override
  String toString() {
    return 'Pool at $poolUrl returned error with code ${poolErrorResponse.responseCode} and message ${poolErrorResponse.message}';
  }
}
