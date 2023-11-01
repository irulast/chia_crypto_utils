class Quote {
  Quote.fromJson(Map<String, dynamic> json)
      : symbol = json['symbol'] as String,
        price = json['price'] as double,
        volume24h = json['volume_24h'] as double,
        volumeChange24h = json['volume_change_24h'] as double,
        marketCap = json['market_cap'] as double,
        marketCapDominance = json['market_cap_dominance'] as double,
        fullyDilutedMarketCap = json['fully_diluted_market_cap'] as double,
        percentChange1h = json['percent_change_1h'] as double,
        percentChange24h = json['percent_change_24h'] as double,
        percentChange7d = json['percent_change_7d'] as double,
        percentChange30d = json['percent_change_30d'] as double,
        lastUpdated = json['last_updated'] as String;
  final String symbol;
  final double price;
  final double volume24h;
  final double volumeChange24h;
  final double marketCap;
  final double marketCapDominance;
  final double fullyDilutedMarketCap;
  final double percentChange1h;
  final double percentChange24h;
  final double percentChange7d;
  final double percentChange30d;
  final String lastUpdated;

  @override
  String toString() =>
      'Quote(symbol: $symbol, price: $price, volume24h: $volume24h, '
      'volumeChange24h: $volumeChange24h, marketCap: $marketCap, '
      'marketCapDominance: $marketCapDominance, fullyDilutedMarketCap: $fullyDilutedMarketCap, '
      'percentChange1h: $percentChange1h, percentChange24h: $percentChange24h, '
      'percentChange7d: $percentChange7d, percentChange30d: $percentChange30d, '
      'lastUpdated: $lastUpdated)';
}
