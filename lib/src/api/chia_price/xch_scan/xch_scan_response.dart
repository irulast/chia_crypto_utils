class XchScanResponse {
  const XchScanResponse({
    required this.priceUsd,
    required this.priceBtc,
  });
  final double priceUsd;
  final double priceBtc;

  XchScanResponse.fromJson(Map<String, dynamic> json)
      : priceUsd = json['usd'] as double,
        priceBtc = json['btc'] as double;
}
