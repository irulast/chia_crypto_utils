class InvalidDIDException implements Exception {
  String? message;

  InvalidDIDException({this.message});

  @override
  String toString() {
    return 'Coin is not a DID${message != null ? ': $message' : ''}';
  }
}
