import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should fail on invalid spend mode code', () {
    expect(
      () => SpendMode.fromCode(2),
      throwsA(isA<InvalidDIDSpendModeCodeException>()),
    );
  });
}
