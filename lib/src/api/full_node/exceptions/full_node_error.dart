class FullNodeErrorException implements Exception{
 String? message;

  FullNodeErrorException([this.message]);

  @override
  String toString() {
    return 'Full node error: $message';
  }
}
