class BadAuthenticationException implements Exception {
  BadAuthenticationException();

  @override
  String toString() {
    return 'Authentication with full node failed. Check that your cert/keys match your network';
  }
}
