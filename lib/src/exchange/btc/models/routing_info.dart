import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class RoutingInfo {
  RoutingInfo({
    this.publicKey,
    this.shortChannelId,
    this.feeBaseMsat,
    this.feeProportionalMillionths,
    this.cltvExpiryDelta,
  });

  String? publicKey;
  String? shortChannelId;
  int? feeBaseMsat;
  int? feeProportionalMillionths;
  int? cltvExpiryDelta;
}
