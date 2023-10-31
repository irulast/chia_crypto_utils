class InvalidDIDSpendModeCodeException implements Exception {
  InvalidDIDSpendModeCodeException({required this.invalidCode});
  final int invalidCode;

  @override
  String toString() {
    return 'Spend mode code $invalidCode is invalid. Must be either 0 or 1';
  }
}
