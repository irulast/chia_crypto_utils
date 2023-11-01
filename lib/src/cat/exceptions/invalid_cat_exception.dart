class InvalidCatException implements Exception {
  InvalidCatException({this.message});
  final String? message;

  @override
  String toString() {
    return 'Invalid CAT${message != null ? ': $message' : ''}';
  }
}
