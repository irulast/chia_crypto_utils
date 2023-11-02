class Platform {
  Platform.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String,
        symbol = json['symbol'] as String,
        slug = json['slug'] as String,
        tokenAddress = json['token_address'] as String;
  final int id;
  final String name;
  final String symbol;
  final String slug;
  final String tokenAddress;

  @override
  String toString() =>
      'Platform(id: $id, name: $name, symbol: $symbol, slug: $slug, '
      'tokenAddress: $tokenAddress)';
}
