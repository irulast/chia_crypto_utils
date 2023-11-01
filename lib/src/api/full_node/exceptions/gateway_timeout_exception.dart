class GatewayTimeoutErrorException implements Exception {
  GatewayTimeoutErrorException([this.message]);
  final String? message;

  @override
  String toString() {
    return 'Gateway timeout error: $message';
  }
}
