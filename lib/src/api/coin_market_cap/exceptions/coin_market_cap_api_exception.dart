class CoinMarketCapApiException implements Exception {
  CoinMarketCapApiException({this.message});
  final String? message;

  @override
  String toString() {
    return 'Error message from CoinMarketCap: $message';
  }
}
