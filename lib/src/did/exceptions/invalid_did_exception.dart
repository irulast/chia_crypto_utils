class InvalidDidException implements Exception {
  InvalidDidException({this.message});
  final String? message;

  @override
  String toString() {
    return 'Coin is not a DID${message != null ? ': $message' : ''}';
  }
}
