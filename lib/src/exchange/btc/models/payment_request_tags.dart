import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PaymentRequestTags {
  PaymentRequestTags({
    required this.paymentHash,
    required this.paymentSecret,
    required this.routingInfo,
    required this.featureBits,
    required this.expirationTime,
    this.fallbackAddress,
    this.description,
    this.payeePublicKey,
    this.purposeCommitHash,
    this.minFinalCltvExpiry,
    this.unknownTags,
  });

  final Bytes paymentHash;
  final Bytes paymentSecret;
  final Bytes routingInfo;
  final int featureBits;
  final int expirationTime;
  Bytes? fallbackAddress;
  String? description;
  JacobianPoint? payeePublicKey;
  Bytes? purposeCommitHash;
  int? minFinalCltvExpiry;
  Map<int, dynamic>? unknownTags;
}
