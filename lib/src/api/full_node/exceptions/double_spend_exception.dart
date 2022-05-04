class DoubleSpendException implements Exception {
  @override
  String toString() => 'Attempted to spend coin twice';
}
