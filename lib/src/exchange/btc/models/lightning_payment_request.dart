import 'package:chia_crypto_utils/src/exchange/btc/models/payment_request_signature.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/payment_request_tags.dart';

class LightningPaymentRequest {
  LightningPaymentRequest({
    required this.paymentRequest,
    required this.prefix,
    required this.network,
    required this.amount,
    required this.timestamp,
    required this.tags,
    required this.signature,
  });

  String paymentRequest;
  String prefix;
  String network;
  double amount;
  int timestamp;
  PaymentRequestTags tags;
  PaymentRequestSignature signature;
}
