class BadSignatureOnPublicKeyException implements Exception {
  BadSignatureOnPublicKeyException();

  @override
  String toString() {
    return 'Could not verify signature on public key.';
  }
}
