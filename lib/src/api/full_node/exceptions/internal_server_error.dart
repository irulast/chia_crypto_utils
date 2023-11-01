class InternalServerErrorException implements Exception {
  InternalServerErrorException([this.message]);
  String? message;

  @override
  String toString() {
    return 'Internal server error: $message';
  }
}
