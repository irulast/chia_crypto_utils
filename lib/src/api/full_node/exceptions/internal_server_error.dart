class InternalServerErrorException implements Exception {
  InternalServerErrorException([this.message]);
  final String? message;

  @override
  String toString() {
    return 'Internal server error: $message';
  }
}
