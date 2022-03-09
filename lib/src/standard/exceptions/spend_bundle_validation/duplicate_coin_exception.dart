class DuplicateCoinException implements Exception {
  static const message = 'Duplicate coin id detected';

  String duplicateIdHex;

  DuplicateCoinException(this.duplicateIdHex);

  @override
  String toString() {
    return '$message: $duplicateIdHex';
  }
}
