import 'package:chia_crypto_utils/src/api/coin_market_cap/models/platform.dart';
import 'package:chia_crypto_utils/src/api/coin_market_cap/models/quote.dart';

class Cryptocurrency {
  Cryptocurrency.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String,
        symbol = json['symbol'] as String,
        slug = json['slug'] as String,
        isActive = json['is_active'] as int == 1,
        isFiat = json['is_fiat'] == null ? null : json['is_fiat'] as int == 1,
        cmcRank = json['cmc_rank'] as int,
        numMarketPairs = json['num_market_pairs'] as int,
        circulatingSupply = json['circulating_supply'] as int,
        totalSupply = json['total_supply'] as int,
        maxSupply = json['maxSupply'] as int?,
        dateAdded = json['date_added'] as String,
        tags = List<String>.from(json['tags'] as Iterable<dynamic>),
        platform = json['platform'] == null
            ? null
            : Platform.fromJson(json['platform'] as Map<String, dynamic>) {
    final quoteData = json['quote'] as Map<String, dynamic>;
    final quoteFirstKey = (json['quote'] as Map<String, dynamic>).keys.first;
    final quoteInfo = quoteData[quoteFirstKey] as Map<String, dynamic>
      ..putIfAbsent('symbol', () => quoteFirstKey);
    quote = Quote.fromJson(quoteInfo);
  }
  int id;
  String name;
  String symbol;
  String slug;
  bool isActive;
  bool? isFiat;
  int cmcRank;
  int numMarketPairs;
  int circulatingSupply;
  int totalSupply;
  int? maxSupply;
  String dateAdded;
  List<String> tags;
  Platform? platform;
  late Quote quote;

  @override
  String toString() => 'Cryptocurrency(id: $id, name: $name, symbol: $symbol, slug: $slug, '
      'isActive: $isActive, isFiat: $isFiat, cmcRank: $cmcRank, numMarketPairs: $numMarketPairs, '
      'circulatingSupply: $circulatingSupply, totalSupply: $totalSupply, maxSupply: $maxSupply, '
      'dateAdded: $dateAdded, tags: $tags, platform: $platform)';
}
