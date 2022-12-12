class PaymentRequestSignature {
  PaymentRequestSignature({
    required this.fullSignature,
    required this.rValue,
    required this.sValue,
    required this.recoveryFlag,
  });

  String fullSignature;
  String rValue;
  String sValue;
  int recoveryFlag;
}
