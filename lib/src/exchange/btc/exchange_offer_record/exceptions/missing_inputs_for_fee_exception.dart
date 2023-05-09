class MissingInputsForFeeException implements Exception {
  MissingInputsForFeeException();

  @override
  String toString() {
    return 'Keychain and coins for fee are required to push spend bundle with fee';
  }
}
