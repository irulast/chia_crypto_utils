class ClvmErrorException implements Exception {
  static const baseMessage = 'clvm error';

  String clvmErrorMessage;

  ClvmErrorException(this.clvmErrorMessage);

  @override
  String toString() {
    return '$baseMessage: $clvmErrorMessage';
  }
}
