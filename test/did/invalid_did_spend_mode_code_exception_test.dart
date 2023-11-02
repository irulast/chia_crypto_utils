import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should return the desired string form with message', () {
    final invalidDIDSpendModeCodeException =
        InvalidDIDSpendModeCodeException(invalidCode: 2);
    expect(
      invalidDIDSpendModeCodeException.toString(),
      'Spend mode code ${invalidDIDSpendModeCodeException.invalidCode} is invalid. '
      'Must be either 0 or 1',
    );
  });
}
