import 'dart:convert';

mixin ToJsonMixin {
  Map<String, dynamic> toJson();
  String toSerializedJson() => jsonEncode(toJson());
  String toPrettyJson() => toSerializedJson()
      .replaceAll(',', '\n')
      .replaceAll('{', '')
      .replaceAll('}', '')
      .replaceAll('"', '')
      .replaceAll('[', '')
      .replaceAll(']', '')
      .replaceAll(':', ': ');
}

extension ToSerializedList on Iterable<ToJsonMixin> {
  String toSerializedJsonList() => jsonEncode(map((e) => e.toJson()).toList());
}
