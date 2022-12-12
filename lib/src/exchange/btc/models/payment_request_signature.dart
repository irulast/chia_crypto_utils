class PaymentRequestSignature {
  PaymentRequestSignature({
    required this.rValue,
    required this.sValue,
    required this.recoveryFlag,
  });

  String rValue;
  String sValue;
  int recoveryFlag;
}
