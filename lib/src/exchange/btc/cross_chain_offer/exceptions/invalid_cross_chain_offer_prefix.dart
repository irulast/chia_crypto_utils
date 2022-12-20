class InvalidCrossChainOfferPrefix implements Exception {
  InvalidCrossChainOfferPrefix();

  @override
  String toString() {
    return "Couldn't verify prefix of offer. Cross-chain offer files use the prefix 'ccoffer' or 'ccoffer_accept'";
  }
}
