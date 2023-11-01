class InvalidInitializationCoinException implements Exception {
  InvalidInitializationCoinException();

  @override
  String toString() {
    return 'Invalid exchange initialization coin';
  }
}
