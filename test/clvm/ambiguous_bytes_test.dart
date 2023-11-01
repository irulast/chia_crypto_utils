import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final expectedBytes = Bytes.fromHex(
      '0xd8a339fbb28da3dd446519abdce314c067313c7955a321bf6c84717b91e18761');
  final hexStringProgram = Program.fromString(expectedBytes.toHexWithPrefix());
  final bytesProgram = expectedBytes.toProgram();

  test('should convert program to bytes', () {
    for (final program in [hexStringProgram, bytesProgram]) {
      expect(
          NftMetadata.getBytesFromTypeAmbiguousProgram(program), expectedBytes);
    }
  });
}
