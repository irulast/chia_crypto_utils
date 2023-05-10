// ignore_for_file: lines_longer_than_80_chars

class InvalidConditionCastException implements Exception {
  InvalidConditionCastException(this.intendedCondition);
  Type intendedCondition;

  @override
  String toString() {
    return 'Attempt to cast program to $intendedCondition failed: wrong condition';
  }
}
