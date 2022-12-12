import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';
import 'package:test/test.dart';

void main() {
  test('should correctly decode lightning payment request', () {
    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    expect(decodedPaymentRequest.prefix, equals('lnbc'));

    expect(decodedPaymentRequest.amount, equals(0.000001));

    expect(
      decodedPaymentRequest.tags.paymentHash!.toHex(),
      equals(
        '63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98',
      ),
    );

    expect(decodedPaymentRequest.tags.description, isNull);

    expect(
      decodedPaymentRequest.tags.minFinalCltvExpiry,
      equals(72),
    );

    expect(
      decodedPaymentRequest.tags.expirationTime,
      equals(86400),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![0].publicKey,
      equals(
        '03a6ce61fcaacd38d31d4e3ce2d506602818e3856b4b44faff1dde9642ba705976',
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![0].shortChannelId,
      equals(
        '8cd6323eba008d1f',
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![0].feeBaseMsat,
      equals(
        100,
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![0].feeProportionalMillionths,
      equals(
        1500,
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![0].cltvExpiryDelta,
      equals(
        9,
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![1].publicKey,
      equals(
        '038f8f113c580048d847d6949371726653e02b928196bad310e3eda39ff61723f6',
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![1].shortChannelId,
      equals(
        '8cd6323eba008d1f',
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![1].feeBaseMsat,
      equals(
        100,
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![1].feeProportionalMillionths,
      equals(
        1500,
      ),
    );

    expect(
      decodedPaymentRequest.tags.routingInfo![1].cltvExpiryDelta,
      equals(
        9,
      ),
    );

    expect(
      decodedPaymentRequest.tags.paymentSecret!.toHex(),
      equals('90901954a57e2eb915254293addd8858bb2162c6f7aa4e5df6fcc71bed8302e4'),
    );

    expect(
      decodedPaymentRequest.tags.featureBits,
      equals(33280),
    );

    expect(
      decodedPaymentRequest.signature.rValue,
      equals(
        'b0d9f8c00da82add97a65ad3dd2468f21294701118b8c66d490f010420affd66',
      ),
    );

    expect(
      decodedPaymentRequest.signature.sValue,
      equals(
        '2389188b8de4211b7d4cb702856257b5533b704bb5b36c923d4d34829a9bb29c',
      ),
    );

    expect(
      decodedPaymentRequest.signature.recoveryFlag,
      equals(1),
    );
  });

  test('should throw exception if prefix is invalid', () {
    const paymentRequest =
        'lnjc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    expect(
      () {
        decodeLightningPaymentRequest(paymentRequest);
      },
      throwsException,
    );
  });
}
