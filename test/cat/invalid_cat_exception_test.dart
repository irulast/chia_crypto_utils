import 'package:chia_crypto_utils/src/cat/exceptions/invalid_cat_exception.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should return the desired string form without message', () {
    expect(InvalidCatException().toString(), 'Coin is not a cat');
  });

  test('should return the desired string form with message', () {
    const message = 'Invalid CAT exception message';
    expect(InvalidCatException(message: message).toString(), 'Coin is not a cat: $message');
  });
}
