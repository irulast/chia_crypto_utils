class ClvmErrorException implements Exception {
  ClvmErrorException(this.clvmErrorMessage);
  static const baseMessage = 'clvm error';

  final String clvmErrorMessage;

  @override
  String toString() {
    return '$baseMessage: $clvmErrorMessage';
  }
}
