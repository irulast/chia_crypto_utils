import 'package:chia_crypto_utils/src/exchange/btc/models/payment_request_tags.dart';

class LightningPaymentRequest {
  LightningPaymentRequest({
    required this.prefix,
    required this.amount,
    required this.timestamp,
    required this.tags,
    required this.signature,
    required this.recoveryFlag,
  });

  String prefix;
  double amount;
  int timestamp;
  PaymentRequestTags tags;
  String signature;
  int recoveryFlag;
}
