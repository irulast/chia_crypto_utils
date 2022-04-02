class ChangePuzzlehashNeededException implements Exception {
  @override
  String toString() {
    return 'Change puzzle hash is required if this spend bundle will result and left over coins.';
  }
}
