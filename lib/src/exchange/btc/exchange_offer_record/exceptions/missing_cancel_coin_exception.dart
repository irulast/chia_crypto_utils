class MissingCancelCoinException implements Exception {
  MissingCancelCoinException();

  @override
  String toString() {
    return 'Could not find cancel coin';
  }
}
