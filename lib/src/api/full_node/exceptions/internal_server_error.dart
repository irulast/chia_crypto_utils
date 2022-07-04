class InternalServerErrorException implements Exception {
  String? message;

  InternalServerErrorException([this.message]);

  @override
  String toString() {
    return 'Internal server error: $message';
  }
}
