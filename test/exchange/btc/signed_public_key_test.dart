import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should correctly create and parse signed public key', () {
    final exchangeService = BtcExchangeService();

    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    final expectedPublicKey = privateKey.getG1();

    final signedPublicKey = exchangeService.createSignedPublicKey(privateKey);

    final publicKey = exchangeService.parseSignedPublicKey(signedPublicKey);

    expect(publicKey, equals(expectedPublicKey));
  });

  test('should throw exception when public key is signed with wrong message', () {
    final exchangeService = BtcExchangeService();

    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    // create signed public key with wrong message
    final publicKey = privateKey.getG1();
    final message = "I don't own this key.".toBytes();
    final signature = AugSchemeMPL.sign(privateKey, message);
    final signedPublicKey = '${publicKey.toHex()}_${signature.toHex()}';

    expect(
      () {
        exchangeService.parseSignedPublicKey(signedPublicKey);
      },
      throwsA(isA<BadSignatureOnPublicKeyException>()),
    );
  });
}
