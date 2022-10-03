abstract class ChiaPriceProvider {
  Future<ChiaPriceResponse> getChiaPrice();
}

abstract class ChiaPriceResponse {
  num get priceUsd;

  Map<String, num> get currencyPriceMap;
}
