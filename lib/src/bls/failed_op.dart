class FailedOp implements Exception {
  String cause;
  FailedOp() : cause = 'Failed to operate.';
}
