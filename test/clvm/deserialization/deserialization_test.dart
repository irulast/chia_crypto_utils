import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final imageBytes =
      File(path.join(path.current, 'test/clvm/deserialization/image.jpeg')).readAsBytesSync();

  test('should correctly serialize and deserialize a big clvm program', () {
    final bigProgram = Program.fromBytes(imageBytes);

    final serializedProgram = bigProgram.serializeHex();
    final deserializedProgram = Program.deserializeHex(serializedProgram);

    expect(deserializedProgram.atom, equals(Bytes(imageBytes)));
  });
}
