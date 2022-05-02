// ignore_for_file: lines_longer_than_80_chars

class ChangePuzzlehashNeededException implements Exception {
  @override
  String toString() {
    return 'Change puzzle hash is required if this spend bundle will result and left over coins.';
  }
}
