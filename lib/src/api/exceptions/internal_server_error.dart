class InternalServeErrorException implements Exception {
  String? message;

  InternalServeErrorException({this.message});

  @override
  String toString() {
    return 'Internal server error: $message';
  }
}
