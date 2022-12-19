class BadSignatureOnOfferFile implements Exception {
  BadSignatureOnOfferFile();

  @override
  String toString() {
    return 'Could not verify signature on offer file.';
  }
}
