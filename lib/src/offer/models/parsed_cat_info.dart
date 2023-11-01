import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class ParsedCatInfo with ToJsonMixin {
  const ParsedCatInfo({
    this.amountMojos = 0,
    this.assetId = '',
    this.name,
    this.ticker,
    this.description,
  });

  factory ParsedCatInfo.fromJson(Map<String, dynamic> json) {
    return ParsedCatInfo(
      amountMojos: pick(json, 'amountMojos').asIntOrThrow(),
      assetId: pick(json, 'assetId').asStringOrThrow(),
      name: json['name'] as String?,
      ticker: json['ticker'] as String?,
      description: json['description'] as String?,
    );
  }
  final int amountMojos;

  double get amount => amountMojos / mojosPerCat;

  final String assetId;
  final String? name;
  final String? ticker;
  final String? description;

  String get type => 'cat';

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'amountMojos': amountMojos,
      'assetId': assetId,
      'name': name,
      'ticker': ticker,
      'description': description,
    };
  }

  @override
  String toString() => 'ParsedCatInfo('
      'amount: $amount, assetId: $assetId, name: $name, '
      'ticker: $ticker, description: $description)';
}
