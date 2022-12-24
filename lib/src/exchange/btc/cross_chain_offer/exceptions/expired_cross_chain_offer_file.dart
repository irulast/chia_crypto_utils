class ExpiredCrossChainOfferFile implements Exception {
  ExpiredCrossChainOfferFile();

  @override
  String toString() {
    return 'This offer is no longer valid.';
  }
}
