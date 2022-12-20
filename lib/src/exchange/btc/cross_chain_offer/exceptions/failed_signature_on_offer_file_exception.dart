class FailedSignatureOnOfferFileException implements Exception {
  FailedSignatureOnOfferFileException();

  @override
  String toString() {
    return "Couldn't sign offer file. Private key doesn't match offer file public key.";
  }
}
