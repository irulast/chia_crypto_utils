import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class ParsedNftInfo with ToJsonMixin {
  const ParsedNftInfo({
    required this.launcherId,
    required this.nftId,
    required this.dataUris,
    this.metaUris,
    this.licenseUris,
    this.editionNumber,
    this.editionTotal,
    this.icon,
  });

  factory ParsedNftInfo.fromJson(Map<String, dynamic> json) {
    return ParsedNftInfo(
      launcherId: pick(json, 'launcherId').asStringOrThrow(),
      nftId: pick(json, 'nftId').asStringOrThrow(),
      dataUris: pick(json, 'dataUris').letStringListOrThrow((s) => s),
      metaUris: pick(json, 'metaUris').letStringListOrNull((s) => s),
      licenseUris: pick(json, 'licenseUris').letStringListOrNull((s) => s),
      editionNumber: pick(json, 'editionNumber').asIntOrNull(),
      editionTotal: pick(json, 'editionTotal').asIntOrNull(),
      icon: pick(json, 'icon').asStringOrNull(),
    );
  }

  factory ParsedNftInfo.fromNft(NftRecord nft) {
    return ParsedNftInfo(
      launcherId: nft.launcherId.toHex(),
      nftId: nft.nftId.address,
      dataUris: nft.metadata.dataUris,
      metaUris: nft.metadata.metaUris,
      licenseUris: nft.metadata.metaUris,
      editionNumber: nft.metadata.editionNumber,
      editionTotal: nft.metadata.editionTotal,
    );
  }

  factory ParsedNftInfo.fromHydratedNft(HydratedNftRecord hydratedRecord) {
    return ParsedNftInfo(
      launcherId: hydratedRecord.launcherId.toHex(),
      nftId: hydratedRecord.nftId.address,
      dataUris: hydratedRecord.metadata.dataUris,
      metaUris: hydratedRecord.metadata.metaUris,
      licenseUris: hydratedRecord.metadata.metaUris,
      editionNumber: hydratedRecord.metadata.editionNumber,
      editionTotal: hydratedRecord.metadata.editionTotal,
      icon: hydratedRecord.data.collection.icon,
    );
  }
  final String launcherId;
  final String nftId;
  final List<String> dataUris;
  final List<String>? metaUris;
  final List<String>? licenseUris;
  final int? editionNumber;
  final int? editionTotal;
  final String? icon;

  String get type => 'nft';

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'launcherId': launcherId,
      'nftId': nftId,
      'dataUris': dataUris,
      'metaUris': metaUris,
      'licenseUris': licenseUris,
      'editionNumber': editionNumber,
      'editionTotal': editionTotal,
    };
  }

  @override
  String toString() => 'ParsedNftInfo('
      'launcherId: $launcherId, nftId: $nftId, dataUris: $dataUris, '
      'metaUris: $metaUris, licenseUris: $licenseUris), '
      'editionNumber: $editionNumber, editionTotal: $editionTotal';
}
