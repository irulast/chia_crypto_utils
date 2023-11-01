class CoinParseException implements Exception {
  CoinParseException(this.expectedOfferedCoins, this.parsedOfferedCoins);
  final int expectedOfferedCoins;
  final int parsedOfferedCoins;

  @override
  String toString() {
    return 'Could not parse all offered coins from offer. Expected $expectedOfferedCoins, parsed $parsedOfferedCoins.';
  }
}
