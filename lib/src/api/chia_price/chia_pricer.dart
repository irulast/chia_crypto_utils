abstract class ChiaPricer {
  ChiaPricer(this.url);
  final String url;

  Future<double> getChiaPriceUsd();
}
