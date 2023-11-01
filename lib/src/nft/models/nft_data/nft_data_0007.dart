import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:equatable/equatable.dart';

class NftData0007 with ToJsonMixin {
  NftData0007({
    required this.name,
    required this.format,
    required this.mintingTool,
    required this.description,
    required this.sensitiveContent,
    required this.collection,
    required this.seriesNumber,
    required this.seriesTotal,
    Map<String, dynamic> json = const {},
    required this.attributes,
  }) : _json = json;

  factory NftData0007.fromJson(Map<String, dynamic> json) {
    return NftData0007(
      name: pick(json, 'name').asStringOrThrow(),
      mintingTool: pick(json, 'minting_tool').asStringOrNull(),
      format: pick(json, 'format').asStringOrThrow(),
      description: pick(json, 'description').asStringOrThrow(),
      sensitiveContent: pick(json, 'sensitive_content').asBoolOrFalse(),
      collection: pick(json, 'collection').letJsonOrThrow(Collection.fromJson),
      attributes:
          pick(json, 'attributes').letJsonListOrNull(NftAttribute.fromJson) ??
              [],
      seriesNumber: pick(json, 'series_number').asIntOrNull(),
      seriesTotal: pick(json, 'series_total').asIntOrNull(),
      json: json,
    );
  }
  static const formatString = 'CHIP-0007';
  static const ccuMintingTool = 'Chia Crypto Utils - Minting Suite';

  final String name;
  final String format;
  final String? mintingTool;
  final String description;
  final bool sensitiveContent;
  final Collection collection;
  final int? seriesNumber;
  final int? seriesTotal;

  final List<Attribute> attributes;

  final Map<String, dynamic> _json;

  NftData0007 withCollectionOverride(NftCollectionOverride collectionOverride) {
    final collectionAttributes = collection.attributes;

    final attributesWithOverrides =
        Map.fromEntries(collectionAttributes.map((e) => MapEntry(e.type, e)));
    for (final attributeOverride
        in collectionOverride.attributes ?? <CollectionAttribute>[]) {
      attributesWithOverrides[attributeOverride.type] = attributeOverride;
    }
    return NftData0007(
      name: name,
      mintingTool: mintingTool,
      format: format,
      description: description,
      seriesNumber: seriesNumber,
      seriesTotal: seriesTotal,
      sensitiveContent: sensitiveContent,
      collection: Collection.fromAttributes(
        id: collection.id,
        name: collectionOverride.name ?? collection.name,
        attributes: attributesWithOverrides.values.toList(),
      ),
      json: _json,
      attributes: attributes,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ..._json,
      'format': format,
      'name': name,
      'description': description,
      if (mintingTool != null) 'minting_tool': mintingTool,
      'sensitive_content': sensitiveContent,
      if (seriesNumber != null) 'series_number': seriesNumber,
      if (seriesTotal != null) 'series_total': seriesTotal,
      'attributes': attributes.map((e) => e.toJson()).toList(),
      'collection': collection.toJson(),
    };
  }
}

class NftAttribute extends Equatable with ToJsonMixin implements Attribute {
  const NftAttribute({
    required this.type,
    required this.value,
  });
  factory NftAttribute.fromJson(Map<String, dynamic> json) {
    return NftAttribute(
      type: pick(json, 'trait_type').asStringOrThrow(),
      value: pick(json, 'value').asStringOrThrow(),
    );
  }

  @override
  final String type;
  @override
  final String value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'trait_type': type,
        'value': value,
      };

  @override
  List<Object?> get props => [type, value];
}
