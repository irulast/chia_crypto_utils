class BlockchainNetwork {
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
  final String name;
  final String? unit;
  final String? ticker;
  final String addressPrefix;
  final String aggSigMeExtraData;
  final int? precision;
  final int? fee;
  final dynamic networkConfig;
}
