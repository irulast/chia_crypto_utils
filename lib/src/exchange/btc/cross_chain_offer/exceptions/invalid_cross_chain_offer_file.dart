class InvalidCrossChainOfferFile implements Exception {
  InvalidCrossChainOfferFile();

  @override
  String toString() {
    return "Couldn't deserialize string to cross chain offer file";
  }
}
