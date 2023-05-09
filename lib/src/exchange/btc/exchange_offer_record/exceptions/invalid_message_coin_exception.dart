class InvalidMessageCoinException implements Exception {
  InvalidMessageCoinException();

  @override
  String toString() {
    return 'Invalid exchange message coin';
  }
}
