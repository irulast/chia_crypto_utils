import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class NftCollectionOverride with ToJsonMixin {
  NftCollectionOverride({
    required this.name,
    required this.attributes,
  });

  factory NftCollectionOverride.fromJson(Map<String, dynamic> json) {
    return NftCollectionOverride(
      name: pick(json, 'name').asStringOrNull(),
      attributes: pick(json, 'attributes').letJsonListOrNull(CollectionAttribute.fromJson) ?? [],
    );
  }

  final String? name;
  final List<CollectionAttribute>? attributes;

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'attributes': attributes?.map((e) => e.toJson()).toList(),
    };
  }
}
