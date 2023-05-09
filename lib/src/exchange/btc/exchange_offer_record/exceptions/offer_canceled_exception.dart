class OfferCanceledException implements Exception {
  OfferCanceledException();

  @override
  String toString() {
    return 'The offer has been canceled';
  }
}
