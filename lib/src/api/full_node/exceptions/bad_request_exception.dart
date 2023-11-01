class BadRequestException implements Exception {
  BadRequestException({this.message});
  final String? message;

  @override
  String toString() {
    return 'Bad request: $message';
  }
}
