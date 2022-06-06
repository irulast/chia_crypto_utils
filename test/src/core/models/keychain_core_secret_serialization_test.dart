import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final keychainSecret = KeychainCoreSecret.generate();

  test('should serialize and deserialize keychain core secret', () {
    final keychainsSecretSerialized = keychainSecret.toBytes();
    final keychainSecretDeSerialized = KeychainCoreSecret.fromBytes(keychainsSecretSerialized);
    final keychainSecretReSerialized = keychainSecretDeSerialized.toBytes();

    expect(keychainSecretReSerialized, equals(keychainsSecretSerialized));
  });
}
