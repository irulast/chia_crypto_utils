class DuplicateCoinException implements Exception {
  DuplicateCoinException(this.duplicateIdHex);
  static const message = 'Duplicate coin id detected';

  String duplicateIdHex;

  @override
  String toString() {
    return '$message: $duplicateIdHex';
  }
}
