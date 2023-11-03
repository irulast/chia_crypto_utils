import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:equatable/equatable.dart';

class Collection {
  Collection._({
    required this.name,
    required this.id,
    required this.attributes,
    required this.icon,
    required this.description,
    required this.banner,
  });
  factory Collection.fromJson(Map<String, dynamic> json) {
    final attributes = pick(json, 'attributes')
        .letJsonListOrThrow(CollectionAttribute.fromJson);

    return Collection.fromAttributes(
      name: pick(json, 'name').asStringOrThrow(),
      id: pick(json, 'id').asStringOrThrow(),
      attributes: attributes,
    );
  }
  factory Collection.fromAttributes({
    required String id,
    required String name,
    required List<Attribute> attributes,
  }) {
    final attributeMap = attributes.toMap();
    return Collection._(
      name: name,
      id: id,
      attributes: attributes,
      description: pick(attributeMap, 'description').asStringOrNull(),
      icon: pick(attributeMap, 'icon').asStringOrNull(),
      banner: pick(attributeMap, 'banner').asStringOrNull(),
    );
  }
  final String name;
  final String id;
  final String? description;
  final String? icon;
  final String? banner;

  final List<Attribute> attributes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'id': id,
        'attributes': attributes.map((e) => e.toJson()).toList(),
      };
}

abstract class Attribute with ToJsonMixin implements Equatable {
  String get type;
  String get value;
}

extension AttributeMap on Iterable<Attribute> {
  Map<String, String> toMap() => {
        for (final attribute in this) attribute.type: attribute.value,
      };
}

class CollectionAttribute extends Equatable
    with ToJsonMixin
    implements Attribute {
  const CollectionAttribute({
    required this.type,
    required this.value,
  });

  const CollectionAttribute.icon(
    this.value,
  ) : type = 'icon';
  const CollectionAttribute.banner(
    this.value,
  ) : type = 'banner';
  const CollectionAttribute.minterLogo(
    this.value,
  ) : type = 'minter_logo';
  const CollectionAttribute.website(
    this.value,
  ) : type = 'website';
  const CollectionAttribute.description(
    this.value,
  ) : type = 'description';
  const CollectionAttribute.twitter(
    this.value,
  ) : type = 'Twitter';

  factory CollectionAttribute.fromJson(Map<String, dynamic> json) {
    return CollectionAttribute(
      type: pick(json, 'type').asStringOrThrow(),
      value: pick(json, 'value').asStringOrThrow(),
    );
  }

  @override
  final String type;
  @override
  final String value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'value': value,
      };

  @override
  List<Object?> get props => [type, value];
}
