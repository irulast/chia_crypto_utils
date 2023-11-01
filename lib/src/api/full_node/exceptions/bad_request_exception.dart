class BadRequestException implements Exception {
  BadRequestException({this.message});
  String? message;

  @override
  String toString() {
    return 'Bad request: $message';
  }
}
