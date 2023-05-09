class MissingMessageCoinChildException implements Exception {
  MissingMessageCoinChildException();

  @override
  String toString() {
    return 'Could not find message coin child';
  }
}
