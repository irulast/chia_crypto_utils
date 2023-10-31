import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class TailInfo with ToJsonMixin {
  TailInfo({
    this.name,
    this.assetId,
    this.code,
    this.category,
    this.supply,
    this.description,
    this.tailProgram,
    this.logoUrl,
    this.websiteUrl,
    this.clsp,
    this.hashgreenInfo,
  });
  factory TailInfo.fromJson(Map<String, dynamic> json) {
    return TailInfo(
      name: pick(json, 'name').asStringOrNull(),
      assetId: pick(json, 'hash').letStringOrNull(Puzzlehash.fromHex),
      code: pick(json, 'code').asStringOrNull(),
      category: pick(json, 'category').asStringOrNull(),
      supply: pick(json, 'supply').asDoubleOrNull(),
      description: pick(json, 'description').asStringOrNull(),
      tailProgram: pick(json, 'tail_reveal').letStringOrNull(Program.parse),
      logoUrl: pick(json, 'nft_uri').asStringOrNull(),
      websiteUrl: pick(json, 'website_url').asStringOrNull(),
      clsp: pick(json, 'chialisp').asStringOrNull(),
      hashgreenInfo: pick(json, 'hashgreen').letJsonOrNull(HashgreenInfo.fromJson),
    );
  }

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

  TailInfo maybeWithOverride(TailInfo? override) {
    if (override == null) {
      return this;
    }
    return withOverride(override);
  }

  TailInfo withOverride(TailInfo override) {
    return TailInfo(
      name: override.name ?? name,
      assetId: override.assetId ?? assetId,
      code: override.code ?? code,
      category: override.category ?? category,
      supply: override.supply ?? supply,
      description: override.description ?? description,
      tailProgram: override.tailProgram ?? tailProgram,
      logoUrl: override.logoUrl ?? logoUrl,
      websiteUrl: override.websiteUrl ?? websiteUrl,
      clsp: override.clsp ?? clsp,
      hashgreenInfo: override.hashgreenInfo ?? hashgreenInfo,
    );
  }

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
      : price = pick(json, 'price').asDoubleOrNull(),
        marketcap = pick(json, 'marketcap').asDoubleOrNull();
  final double? price;
  final num? marketcap;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'price': price,
        'marketcap': marketcap,
      };
}
