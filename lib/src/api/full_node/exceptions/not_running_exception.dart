class NotRunningException implements Exception {
  String url;

  NotRunningException(this.url);

  @override
  String toString() {
    return 'Full node is not running at $url';
  }
}
