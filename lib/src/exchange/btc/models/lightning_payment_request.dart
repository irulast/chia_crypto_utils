import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/payment_request_tags.dart';

class LightningPaymentRequest {
  LightningPaymentRequest({
    required this.tags,
    required this.signature,
  });

  PaymentRequestTags tags;
  String signature;
}
