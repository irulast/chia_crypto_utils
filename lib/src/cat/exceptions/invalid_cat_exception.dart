class InvalidCatException implements Exception {
  InvalidCatException({this.message});
  String? message;

  @override
  String toString() {
    return 'Coin is not a cat${message != null ? ': $message' : ''}';
  }
}
