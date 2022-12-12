class RouteInfo {
  RouteInfo({
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
