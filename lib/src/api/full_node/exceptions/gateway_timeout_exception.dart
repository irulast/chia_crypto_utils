class GatewayTimeoutErrorException implements Exception {
  GatewayTimeoutErrorException([this.message]);
  String? message;

  @override
  String toString() {
    return 'Gateway timeout error: $message';
  }
}
