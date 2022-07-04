class GatewayTimeoutErrorException implements Exception {
  String? message;

  GatewayTimeoutErrorException([this.message]);

  @override
  String toString() {
    return 'Gateway timeout error: $message';
  }
}
