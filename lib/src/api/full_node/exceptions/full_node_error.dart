class FullNodeErrorException implements Exception {
  FullNodeErrorException(this.code, [this.message]);
  String? message;
  int code;

  @override
  String toString() {
    return 'Full node error: {code: $code, msg: $message}';
  }
}
