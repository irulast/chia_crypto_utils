class DuplicateCoinException implements Exception {
  DuplicateCoinException(this.duplicateIdHex);
  static const message = 'Duplicate coin id detected';

  final String duplicateIdHex;

  @override
  String toString() {
    return '$message: $duplicateIdHex';
  }
}
