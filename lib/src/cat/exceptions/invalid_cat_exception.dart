class InvalidCatException implements Exception {
  String? message;

  InvalidCatException({this.message});

  @override
  String toString() {
    return 'Coin is not a cat${message != null ? ': $message' : ''}';
  }
}
