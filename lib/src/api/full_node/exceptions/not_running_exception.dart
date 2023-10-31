class NotRunningException implements Exception {
  NotRunningException(this.url);
  final String url;

  @override
  String toString() {
    return 'Full node is not running at $url';
  }
}
