import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';
import 'package:test/test.dart';

void main() {
  test('should correctly decode lightning payment request', () {
    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final paymentHash = decodedPaymentRequest.tags.paymentHash;
    final description = decodedPaymentRequest.tags.description;
    final minFinalCltvExpiry = decodedPaymentRequest.tags.minFinalCltvExpiry;
    final expirationTime = decodedPaymentRequest.tags.expirationTime;
    final routingInfo = decodedPaymentRequest.tags.routingInfo;
    final paymentSecret = decodedPaymentRequest.tags.paymentSecret;
    final featureBits = decodedPaymentRequest.tags.featureBits;
    final signature = decodedPaymentRequest.signature;

    expect(
      paymentHash.toHex(),
      equals(
        '63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98',
      ),
    );

    expect(description, isNull);

    expect(
      minFinalCltvExpiry,
      equals(72),
    );

    expect(
      expirationTime,
      equals(86400),
    );

    expect(
      routingInfo.toHex(),
      equals(
        '000e3e3c44f1600123611f5a524dc5c9994f80ae4a065aeb4c438fb68e7fd85c8fda3358c8fae802347c00000190000017700024',
      ),
    );

    expect(
      paymentSecret.toHex(),
      equals('90901954a57e2eb915254293addd8858bb2162c6f7aa4e5df6fcc71bed8302e4'),
    );

    expect(
      featureBits,
      equals(33280),
    );

    expect(
      signature,
      equals(
        '2371190298897753049932765642821337431726569419501471916101239177565213090033171301461855787167292412780963216525100198721191441428010383701341990407766187009',
      ),
    );
  });
}
