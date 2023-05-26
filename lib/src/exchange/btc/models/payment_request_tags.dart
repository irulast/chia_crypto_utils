import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// [LightningPaymentRequest] tagged data fields. All tagged fields are optional. See https://github.com/lightning/bolts/blob/master/11-payment-encoding.md#tagged-fields for more information.
class PaymentRequestTags {
  PaymentRequestTags({
    this.paymentHash,
    this.paymentSecret,
    this.routingInfo,
    this.featureBits,
    this.timeout,
    this.fallbackAddress,
    this.description,
    this.payeePublicKey,
    this.purposeCommitHash,
    this.minFinalCltvExpiry,
    this.metadata,
    this.unknownTags,
  });

  Bytes? paymentHash;
  Bytes? paymentSecret;
  List<RouteInfo>? routingInfo;

  // featureBits is in binary string representation
  String? featureBits;
  int? timeout;
  FallbackAddress? fallbackAddress;
  String? description;
  Bytes? payeePublicKey;
  Bytes? purposeCommitHash;
  int? minFinalCltvExpiry;
  Bytes? metadata;
  Map<int, dynamic>? unknownTags;
}
