import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should return the desired string form without message', () {
    expect(InvalidDidException().toString(), 'Coin is not a DID');
  });

  test('should return the desired string form with message', () {
    const message = 'Invalid DID exception message';
    expect(InvalidDidException(message: message).toString(),
        'Coin is not a DID: $message');
  });
}
