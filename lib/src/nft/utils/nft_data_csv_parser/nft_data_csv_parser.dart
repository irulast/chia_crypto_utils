import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/nft/utils/nft_data_csv_parser/nft_theme_csv_data.dart';
import 'package:chia_crypto_utils/src/nft/utils/nft_data_csv_parser/uploadable_value.dart';
import 'package:csv/csv.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:uuid/uuid.dart';

class NftDataCsvParser {
  static const converter = CsvToListConverter();

  static const _collectionIdRow = 9;
  static const _collectionIdColumn = 1;

  String? _getCollectionIdFromRows(List<List<dynamic>> rows) {
    return pick(rows[_collectionIdRow][_collectionIdColumn]).asStringOrNull();
  }

  void setCollectionIdIfEmpty(File file) {
    final rows = converter.convert(file.readAsStringSync());

    final collectionId = _getCollectionIdFromRows(rows);
    if (collectionId == null || collectionId.isEmpty) {
      final uuid = const Uuid().v4();
      rows[_collectionIdRow][_collectionIdColumn] = uuid;
      file.writeAsStringSync(const ListToCsvConverter().convert(rows));
    }
  }

  /// parses collection data and adds collection id if not present
  CsvCollectionData parseCollectionDataFromFile(File file) {
    final rows = converter.convert(file.readAsStringSync());
    final fieldRows = rows.sublist(0, 10);

    final collectionId = _getCollectionIdFromRows(fieldRows)!;

    if (!Uuid.isValidUUID(fromString: collectionId)) {
      throw Exception('collection id is not a valid uuid: "$collectionId"');
    }

    final attributeRows = rows.sublist(13);

    return CsvCollectionData(
      name: pick(fieldRows[0][1]).asStringOrThrow(),
      description: pick(fieldRows[1][1]).asStringOrThrow(),
      twitter: pick(fieldRows[2][1]).asStringOrThrow(),
      website: pick(fieldRows[3][1]).asStringOrThrow(),
      icon: UploadableValue(pick(fieldRows[4][1]).asStringOrThrow())..assertImage(),
      banner: UploadableValue(pick(fieldRows[5][1]).asStringOrThrow())..assertImage(),
      editionTotal: pick(fieldRows[6][1]).asIntOrNull(),
      seriesTotal: pick(fieldRows[7][1]).asIntOrNull(),
      seriesNumber: pick(fieldRows[8][1]).asIntOrNull(),
      collectionId: collectionId,
      attributes: attributeRows
          .map(
            (row) => UploadableAttribute(
              type: pick(row[0]).asStringOrThrow(),
              value: UploadableValue(row[1].toString()),
            ),
          )
          .toList(),
    );
  }

  /// parses nft data from csv
  List<CsvNftData> parseNftRowsFromFile(File file) {
    final rows = converter.convert(file.readAsStringSync());
    final headerRow = rows[1];
    final columnNumberToAttributeType =
        Map.fromEntries(headerRow.asMap().entries.toList().sublist(5));
    final dataRows = rows.sublist(2);

    return dataRows.map((row) {
      return CsvNftData(
        count: pick(row[0]).asIntOrThrow(),
        name: pick(row[1]).asStringOrThrow(),
        description: pick(row[2]).asStringOrThrow(),
        sensitiveContent: pick(row[3]).asBoolOrFalse(),
        image: UploadableValue(pick(row[4]).asStringOrThrow())..assertImage(),
        cardFrontFile: pick(row[5]).asNonEmptyStringOrNull(),
        cardBackFile: pick(row[6]).asNonEmptyStringOrNull(),
        attributes: row
            .asMap()
            .entries
            .toList()
            .sublist(7)
            .map(
              (e) => UploadableAttribute(
                type: pick(columnNumberToAttributeType[e.key]).asStringOrThrow(),
                value: UploadableValue(e.value.toString()),
              ),
            )
            .toList(),
      );
    }).toList();
  }

  NftThemeCsvData parseThemeDataFromFile(File file) {
    final rows = converter.convert(file.readAsStringSync());

    final sizeTableRowIndex =
        rows.indexWhere((row) => pick(row[0]).asStringOrThrow().contains('size'));

    final fieldRows = rows.sublist(0, sizeTableRowIndex);

    final imageRows = rows.sublist(sizeTableRowIndex + 1);

    final imageData = imageRows.map((e) {
      final size = pick(e[0]).asIntOrThrow();
      final image = pick(e[1]).asNonEmptyStringOrNull();
      final background = pick(e[2]).asNonEmptyStringOrNull();
      return ThemeImageData(
        size: size,
        image: (image != null) ? (UploadableValue(image)..assertImage()) : null,
        background: background != null ? (UploadableValue(background)..assertImage()) : null,
      );
    }).toList();

    final fieldMap = Map.fromEntries(
      fieldRows
          .map((r) => MapEntry(pick(r[0]).asNonEmptyStringOrNull(), r[1]))
          .where((element) => element.key != null),
    ).cast<String, dynamic>();

    return NftThemeCsvData(
      name: pick(fieldMap, 'name').asStringOrThrow(),
      accentColor: pick(fieldMap, 'accent_color').asStringOrThrow(),
      brightness: pick(fieldMap, 'brightness').asStringOrThrow(),
      buttonColor: pick(fieldMap, 'button_color').asStringOrThrow(),
      buttonOpacity: pick(fieldMap, 'button_opacity').asDoubleOrThrow(),
      nftTextOutlineColor: pick(fieldMap, 'nft_text_outline_color').asStringOrNull(),
      nftTextColor: pick(fieldMap, 'nft_text_color').asStringOrNull(),
      imageData: imageData,
    );
  }
}
