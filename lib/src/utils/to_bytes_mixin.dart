import 'dart:convert';

import 'package:chia_crypto_utils/src/clvm/bytes.dart';
import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/spawn_and_wait_for_isolate.dart';
import 'package:hex/hex.dart';

mixin ToBytesMixin {
  Bytes toBytes();

  static Map<String, dynamic> _toBytesTask(ToBytesMixin item) {
    return {
      'serialized': item.toBytes().byteList,
    };
  }

  Future<Bytes> toBytesAsync() {
    return spawnAndWaitForIsolate(
      taskArgument: this,
      isolateTask: _toBytesTask,
      handleTaskCompletion: (taskResultJson) {
        return Bytes((taskResultJson['serialized'] as List<dynamic>).cast());
      },
    );
  }

  String toHex() => const HexEncoder().convert(toBytes());
  String toHexWithPrefix() => Bytes.bytesPrefix + toHex();
}

extension StringToBytesX on String {
  Bytes toBytes() => Bytes(utf8.encode(this));
  Bytes hexToBytes() {
    if (startsWith(Bytes.bytesPrefix)) {
      return Bytes(
          const HexDecoder().convert(replaceFirst(Bytes.bytesPrefix, '')));
    }
    return Bytes(const HexDecoder().convert(this));
  }
}
