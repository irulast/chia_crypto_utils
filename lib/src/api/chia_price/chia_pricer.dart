abstract class ChiaPricer {
  ChiaPricer(this.url);
  final String url;
  //TODO: make price response interface implemn\ented by crypto pricers
  Future<double> getChiaPriceUsd();
}
