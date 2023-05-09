// ignore_for_file: avoid_catching_errors

import 'package:deep_pick/deep_pick.dart';

extension CustomLets on Pick {
  R? letJsonOrNull<R>(R Function(Map<String, dynamic> json) parseJson) {
    return _parsePossibleXFromJson(value, parseJson);
  }

  R letJsonOrThrow<R>(R Function(Map<String, dynamic> json) parseJson) {
    final item = _parsePossibleXFromJson(value, parseJson);
    if (item == null) throw Exception('failed parsing as json: $value at $path');
    return item;
  }

  List<R>? letJsonListOrNull<R>(R Function(Map<String, dynamic> json) parseJson) {
    return _parsePossibleListOfXFromListOfJson(value, parseJson);
  }

  List<R> letJsonListOrThrow<R>(R Function(Map<String, dynamic> json) parseJson) {
    final list = _parsePossibleListOfXFromListOfJson(value, parseJson);
    if (list == null) throw Exception('failed parsing as list of json: $value at $path');
    return list;
  }

  R? letStringOrNull<R>(R Function(String string) parseString) {
    return _parsePossibleXFromString(value, parseString);
  }

  R letStringOrThrow<R>(R Function(String string) parseString) {
    final item = _parsePossibleXFromString(value, parseString);
    if (item == null) throw Exception('failed parsing as string: $value at $path');
    return item;
  }

  List<R>? letStringListOrNull<R>(R Function(String string) parseString) {
    return _parsePossibleListOfXFromListOfStrings(value, parseString);
  }

  List<R> letStringListOrThrow<R>(R Function(String string) parseString) {
    final item = _parsePossibleListOfXFromListOfStrings(value, parseString);
    if (item == null) throw Exception('failed parsing as list of strings: $value at $path');
    return item;
  }
}

List<T>? _parsePossibleListOfXFromListOfJson<T>(
  dynamic list,
  T Function(Map<String, dynamic> json) xFromJson,
) {
  if (list is! List<dynamic>) {
    return null;
  }
  final listOfx = <T>[];

  for (final item in list) {
    final x = _parsePossibleXFromJson(item, xFromJson);
    if (x != null) {
      listOfx.add(x);
    }
  }
  return listOfx;
}

T? _parsePossibleXFromJson<T>(
  dynamic maybeJson,
  T Function(Map<String, dynamic> json) xFromJson,
) {
  final json = _parsePossibleJson(maybeJson);
  if (json == null) {
    return null;
  }
  try {
    final x = xFromJson(json);
    return x;
  } catch (e) {
    return null;
  }
}

Map<String, dynamic>? _parsePossibleJson(dynamic item) {
  if (item is Map<String, dynamic>) {
    return item;
  }
  return null;
}

List<T>? _parsePossibleListOfXFromListOfStrings<T>(
  dynamic list,
  T Function(String string) xFromString,
) {
  if (list is! List<dynamic>) {
    return null;
  }
  final listOfx = <T>[];

  for (final item in list) {
    if (item is String) {
      try {
        final x = xFromString(item);
        listOfx.add(x);
      } catch (_) {}
    }
  }
  return listOfx;
}

T? _parsePossibleXFromString<T>(
  dynamic item,
  T Function(String string) xFromString, {
  bool allowEmpty = false,
}) {
  final string = _parsePossibleString(item, allowEmpty: allowEmpty);
  if (string == null) {
    return null;
  }

  try {
    final x = xFromString(string);
    return x;
  } catch (e) {
    return null;
  }
}

String? _parsePossibleString(dynamic item, {bool allowEmpty = false}) {
  if (item is! String || (!allowEmpty && item.isEmpty)) {
    return null;
  }

  return item;
}
