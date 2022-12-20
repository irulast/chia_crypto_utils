class InvalidCrossChainOfferFileType implements Exception {
  InvalidCrossChainOfferFileType();

  @override
  String toString() {
    return 'Invalid cross chain offer file type.';
  }
}
