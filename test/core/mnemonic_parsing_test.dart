import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final secret = KeychainCoreSecret.generate();

  test('should correctly parse mnemonic', () {
    final fromString = KeychainCoreSecret.fromMnemonicString(secret.mnemonicString);
    expect(fromString.fingerprint, secret.fingerprint);
    expect(fromString.mnemonicString, secret.mnemonicString);
    expect(fromString.mnemonic, secret.mnemonic);
  });
}
