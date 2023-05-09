class InvalidExchangePublicKeyException implements Exception {
  InvalidExchangePublicKeyException();

  @override
  String toString() {
    return "Can't find exchange private key for public key";
  }
}
