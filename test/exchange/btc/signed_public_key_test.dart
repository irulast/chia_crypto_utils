import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';
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
}
