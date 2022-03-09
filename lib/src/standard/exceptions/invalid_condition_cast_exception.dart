class InvalidConditionCastException implements Exception {
  Type intendedCondition;

  InvalidConditionCastException(this.intendedCondition);

  @override
  String toString() {
    return 'Attempt to cast program to ${intendedCondition.toString()} failed: wrong condition';
  }
}
