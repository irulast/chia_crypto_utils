class FullNodeErrorException implements Exception {
  String? message;
  int code;

  FullNodeErrorException(this.code, [this.message]);

  @override
  String toString() {
    return 'Full node error: {code: $code, msg: $message}';
  }
}
