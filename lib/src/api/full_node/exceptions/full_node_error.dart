class FullNodeErrorException implements Exception {
  FullNodeErrorException(this.code, [this.message]);
  final String? message;
  final int code;

  @override
  String toString() {
    return 'Full node error: {code: $code, msg: $message}';
  }
}
