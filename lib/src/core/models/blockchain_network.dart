class BlockchainNetwork {
  String name;
  String? unit;
  // TODO(nvjoshi2): logo https://pub.dev/packages/image
  String? ticker;
  String addressPrefix;
  String aggSigMeExtraData;
  int? precision;
  int? fee;
  dynamic networkConfig;

  BlockchainNetwork({
    required this.name,
    this.unit,
    this.ticker,
    required this.addressPrefix,
    required this.aggSigMeExtraData,
    this.precision,
    this.fee,
    this.networkConfig,
  });
}
