import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final bytes = Bytes.encodeFromString('yo wassup').sha256Hash();

  final ph = Puzzlehash(bytes);

  test('bytes should accurately compare to puzzle hash', () {
    expect(bytes, ph);
  });
}
