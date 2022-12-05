abstract class ChiaPriceProvider {
  Future<ChiaPriceResponse> getChiaPrice();
}

abstract class ChiaPriceResponse {
  num get priceUsd;
  num get priceBtc;

  Map<String, num> get currencyPriceMap;
}
