class InvalidCrossChainOfferType implements Exception {
  InvalidCrossChainOfferType(this.expectedType);

  final String expectedType;

  @override
  String toString() {
    return 'Wrong offer file type. Expected type $expectedType';
  }
}
