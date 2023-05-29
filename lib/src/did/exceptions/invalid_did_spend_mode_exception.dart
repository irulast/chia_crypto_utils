class InvalidDIDSpendModeCodeException implements Exception {
  int invalidCode;

  InvalidDIDSpendModeCodeException({required this.invalidCode});

  @override
  String toString() {
    return 'Spend mode code $invalidCode is invalid. Must be either 0 or 1';
  }
}
