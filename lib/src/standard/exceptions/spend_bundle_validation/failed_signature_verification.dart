class FailedSignatureVerificationException implements Exception {
  static const message = 'Failed signature verification';

  @override
  String toString() {
    return message;
  }
}
