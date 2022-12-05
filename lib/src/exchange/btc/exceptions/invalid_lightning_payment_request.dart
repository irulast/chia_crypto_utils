class InvalidLightningPaymentRequest implements Exception {
  InvalidLightningPaymentRequest();

  @override
  String toString() {
    return 'Invalid lightning payment request format.';
  }
}
