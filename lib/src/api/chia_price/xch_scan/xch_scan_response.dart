import 'package:chia_crypto_utils/src/api/chia_price/chia_price_provider.dart';

class XchScanResponse implements ChiaPriceResponse {
  const XchScanResponse({
    required this.currencyPriceMap,
  });
  @override
  num get priceUsd => currencyPriceMap['usd']!;

  @override
  num get priceBtc => currencyPriceMap['btc']!;

  XchScanResponse.fromJson(Map<String, dynamic> json)
      : currencyPriceMap = Map<String, num>.from(json);

  @override
  final Map<String, num> currencyPriceMap;
}
