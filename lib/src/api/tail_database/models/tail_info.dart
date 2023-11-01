import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class TailInfo with ToJsonMixin {
  TailInfo({
    required this.name,
    required this.assetId,
    required this.code,
    required this.category,
    required this.supply,
    required this.description,
    required this.tailProgram,
    required this.logoUrl,
    required this.websiteUrl,
    required this.clsp,
    required this.hashgreenInfo,
  });
  TailInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String?,
        clsp = json['chialisp'] as String?,
        assetId = json['hash'] == null ? null : Puzzlehash.fromHex(json['hash'] as String),
        code = json['code'] as String?,
        category = json['category'] as String?,
        supply = json['supply'] as num?,
        description = json['description'] as String?,
        tailProgram =
            json['tail_reveal'] == null ? null : Program.parse(json['tail_reveal'] as String),
        hashgreenInfo = json['hashgreen'] == null
            ? null
            : HashgreenInfo.fromJson(json['hashgreen'] as Map<String, dynamic>),
        logoUrl = json['nft_uri'] as String?,
        websiteUrl = json['website_url'] as String?;
        
  final String? name;
  final String? clsp;
  final Puzzlehash? assetId;
  final String? code;
  final String? category;
  final num? supply;
  final String? description;
  final Program? tailProgram;
  final String? logoUrl;
  final String? websiteUrl;
  final HashgreenInfo? hashgreenInfo;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'chialisp': clsp,
        'hash': assetId?.toHex(),
        'code': code,
        'category': category,
        'supply': supply,
        'description': description,
        'tail_reveal': tailProgram?.toString(),
        'hashgreen': hashgreenInfo?.toJson(),
        'nft_uri': logoUrl,
        'website_url': websiteUrl,
      };

  @override
  String toString() => 'TailInfo(name: $name, clsp: $clsp, assetId: $assetId, '
      'code: $code, category: $category, supply: $supply, '
      'description: $description, tailProgram: $tailProgram, logoUrl: $logoUrl, '
      'websiteUrl: $websiteUrl, hashgreenInfo: $hashgreenInfo)';
}

class HashgreenInfo {
  HashgreenInfo({
    required this.price,
    required this.marketcap,
  });
  HashgreenInfo.fromJson(Map<String, dynamic> json)
      : price = (json['price'] as String?) == null ? null : double.parse(json['price'] as String),
        marketcap = json['marketcap'] as num?;
  final double? price;
  final num? marketcap;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'price': price,
        'marketcap': marketcap,
      };
}
