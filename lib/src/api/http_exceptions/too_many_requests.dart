class TooManyRequestsException implements Exception {
  TooManyRequestsException([this.uri]);

  final Uri? uri;

  @override
  String toString() {
    final b = StringBuffer()..write('TooManyRequestsException: ');
    final uri = this.uri;
    if (uri != null) {
      b.write(', uri = $uri');
    }
    return b.toString();
  }
}
