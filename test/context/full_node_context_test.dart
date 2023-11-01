import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  const testUrl = 'https://full-node-url.dev';
  final testCertificateBytes = Bytes.encodeFromString('these are certificate bytes');
  final testKeyBytes = Bytes.encodeFromString('these are key bytes');
  test('should save full node context correctly', () {
    FullNodeContext().setUrl(testUrl);
    FullNodeContext().setCertificateBytes(testCertificateBytes);
    FullNodeContext().setKeyBytes(testKeyBytes);

    expect(FullNodeContext().url, equals(testUrl));
    expect(FullNodeContext().certificateBytes, equals(testCertificateBytes));
    expect(FullNodeContext().keyBytes, equals(testKeyBytes));
  });
}
