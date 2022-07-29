import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class TailInfo {
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

  final String name;
  final String? clsp;
  final Puzzlehash assetId;
  final String code;
  final String category;
  final int? supply;
  final String description;
  final Program? tailProgram;
  final String? logoUrl;
  final String? websiteUrl;
  final HashgreenInfo hashgreenInfo;

  TailInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        clsp = json['chialisp'] as String?,
        assetId = Puzzlehash.fromHex(json['hash'] as String),
        code = json['code'] as String,
        category = json['category'] as String,
        supply = json['supply'] as int?,
        description = json['description'] as String,
        tailProgram =(json['clvm'] != null) ?  Program.parse(json['clvm'] as String) : null,
        hashgreenInfo = HashgreenInfo.fromJson(json['hashgreen'] as Map<String, dynamic>),
        logoUrl = json['logo_url'] as String?,
        websiteUrl = json['website_url'] as String?;
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
}
