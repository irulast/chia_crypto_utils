class MultipleOriginCoinsException implements Exception {
  static const message = 'More than one origin coin creating output';

  @override
  String toString() {
    return message;
  }
}
