import 'package:chia_crypto_utils/src/nft/utils/nft_data_csv_parser/uploadable_value.dart';

class CsvCollectionData {
  const CsvCollectionData({
    required this.name,
    required this.description,
    required this.twitter,
    required this.website,
    required this.icon,
    required this.banner,
    required this.attributes,
    required this.editionTotal,
    required this.seriesNumber,
    required this.seriesTotal,
    required this.collectionId,
  });

  final String name;
  final String description;
  final String twitter;
  final String website;
  final UploadableValue icon;
  final UploadableValue banner;

  final int? editionTotal;
  final int? seriesNumber;
  final int? seriesTotal;
  final String collectionId;

  final List<UploadableAttribute> attributes;
}
