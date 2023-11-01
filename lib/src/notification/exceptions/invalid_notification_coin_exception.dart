class InvalidNotificationCoinException implements Exception {
  InvalidNotificationCoinException();

  @override
  String toString() {
    return 'Coin is not a notification coin';
  }
}
