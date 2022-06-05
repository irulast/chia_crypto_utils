// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Bytes serializeListChia(List<ToBytesMixin> items) {
  // 32 bytes indicating length of serialized list.
  // from https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/util/streamable.py#L241
  var bytes = Bytes(intTo32Bits(items.length));
  for (final item in items) {
    bytes += item.toBytes();
  }
  return bytes;
}

Bytes serializeList(List<dynamic> items) {
  final bytes = items.fold(
    <int>[],
    (List<int> previousValue, dynamic item) => <int>[...previousValue, ...serializeItem(item)],
  );
  return Bytes(bytes);
}

Bytes serializeItem(dynamic item) {
  Bytes? bytes;
  int? length;

  if (item is int) {
    bytes = intTo64Bits(item);
    length = bytes.length;
  } else if (item is bool) {
    bytes = item ? Bytes([1]) : Bytes([0]);
    length = bytes.length;
  } else if (item is String) {
    bytes = item.toBytes();
    length = bytes.length;
  } else if (item is Bytes) {
    bytes = item;
    length = item.length;
  } else if (item is ToBytesMixin) {
    bytes = item.toBytes();
    length = bytes.length;
  } else if (item is Map) {
    final bytesList = <int>[];
    item.forEach((dynamic key, dynamic value) {
      final keyBytes = serializeItem(key);
      final valueBytes = serializeItem(value);
      bytesList.addAll([...keyBytes, ...valueBytes]);
    });
    bytes = Bytes(bytesList);
    length = item.length;
  } else if (item is List) {
    final listBytes = <int>[];
    for (final listItem in item) {
      listBytes.addAll(serializeItem(listItem));
    }
    bytes = Bytes(listBytes);
    length = item.length;
  } else {
    throw UnimplementedError();
  }

  final lengthBytes = intTo32Bits(length);
  return Bytes([...lengthBytes, ...bytes]);
}

String stringfromStream(Iterator<int> iterator) {
  final stringLengthBytes = iterator.extractBytesAndAdvance(4);
  final stringLength = bytesToInt(stringLengthBytes, Endian.big);
  final stringBytes = iterator.extractBytesAndAdvance(stringLength);
  return utf8.decode(stringBytes);
}
