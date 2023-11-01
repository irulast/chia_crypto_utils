import 'package:chia_crypto_utils/src/nft/utils/nft_data_csv_parser/uploadable_value.dart';
import 'package:equatable/equatable.dart';

class CsvNftData extends Equatable {
  const CsvNftData({
    required this.count,
    required this.name,
    required this.description,
    required this.sensitiveContent,
    required this.image,
    required this.attributes,
    required this.cardFrontFile,
    required this.cardBackFile,
  });
  final int count;
  final String name;
  final String description;
  final bool sensitiveContent;

  final UploadableValue image;
  final String? cardFrontFile;
  final String? cardBackFile;

  final List<UploadableAttribute> attributes;

  @override
  List<Object?> get props => [
        count,
        name,
        description,
        sensitiveContent,
        image,
        ...attributes,
      ];
}
