import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  const testPoolUrl = 'https://cool-pool.io';
  final testCertificateBytes = Bytes.encodeFromString('these are certificate bytes');

  test('should save full node context correctly', () {
    PoolContext().setPoolUrl(testPoolUrl);
    PoolContext().setCertificateBytes(testCertificateBytes);

    expect(PoolContext().poolUrl, equals(testPoolUrl));
    expect(PoolContext().certificateBytes, equals(testCertificateBytes));
  });
}
