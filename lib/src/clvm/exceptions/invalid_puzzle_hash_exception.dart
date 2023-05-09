class InvalidPuzzleHashException implements Exception {
  @override
  String toString() {
    return 'Invalid puzzle hash. (Not exactly 32 bytes)';
  }
}
