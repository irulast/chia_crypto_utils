import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

mixin ToJsonMixin {
  static const indentEncoder = JsonEncoder.withIndent('  ');
  Map<String, dynamic> toJson();

  static Map<String, dynamic> _toJsonTask(ToJsonMixin item) {
    return item.toJson();
  }

  Future<Map<String, dynamic>> toJsonAsync() {
    return spawnAndWaitForIsolate(
      taskArgument: this,
      isolateTask: _toJsonTask,
      handleTaskCompletion: (taskResultJson) => taskResultJson,
    );
  }

  String toSerializedJson() => jsonEncode(toJson());
  String toIndentedJson() {
    return indentEncoder.convert(toJson());
  }

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
