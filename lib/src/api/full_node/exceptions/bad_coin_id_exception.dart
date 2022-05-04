class BadCoinIdException implements Exception {
  @override
  String toString() => 'Invalid coin id given to full node';
}
