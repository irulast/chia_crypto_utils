import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';
import 'package:test/test.dart';

void main() {
  test('should correctly decode lightning payment request', () {
    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    expect(decodedPaymentRequest.prefix, equals('lnbc'));

    expect(decodedPaymentRequest.network, equals('mainnet'));

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
      decodedPaymentRequest.tags.timeout,
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
      decodedPaymentRequest.tags.featureBits,
      equals(00001000001000000000),
    );

    expect(
      decodedPaymentRequest.tags.paymentSecret!.toHex(),
      equals('90901954a57e2eb915254293addd8858bb2162c6f7aa4e5df6fcc71bed8302e4'),
    );

    expect(
      decodedPaymentRequest.signature.fullSignature,
      equals(
        'b0d9f8c00da82add97a65ad3dd2468f21294701118b8c66d490f010420affd662389188b8de4211b7d4cb702856257b5533b704bb5b36c923d4d34829a9bb29c',
      ),
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

  test('should correctly decode lightning payment request fallback address', () {
    const paymentRequest =
        'lntb20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygshp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfpp3x9et2e20v6pu37c5d9vax37wxq72un989qrsgqdj545axuxtnfemtpwkc45hx9d2ft7x04mt8q7y6t0k2dge9e7h8kpy9p34ytyslj3yu569aalz2xdk8xkd7ltxqld94u8h2esmsmacgpghe9k8';
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    expect(decodedPaymentRequest.prefix, equals('lntb'));

    expect(decodedPaymentRequest.network, equals('testnet'));

    expect(decodedPaymentRequest.amount, equals(0.02));

    expect(decodedPaymentRequest.timestamp, equals(1496314658));

    expect(
      decodedPaymentRequest.tags.paymentHash!.toHex(),
      equals(
        '0001020304050607080900010203040506070809000102030405060708090102',
      ),
    );

    expect(decodedPaymentRequest.tags.fallbackAddress!.version, equals(17));

    expect(
      decodedPaymentRequest.tags.fallbackAddress!.addressHash,
      equals('3172b5654f6683c8fb146959d347ce303cae4ca7'),
    );

    expect(
      decodedPaymentRequest.tags.featureBits,
      equals(100000100000000),
    );

    expect(
      decodedPaymentRequest.tags.paymentSecret!.toHex(),
      equals('1111111111111111111111111111111111111111111111111111111111111111'),
    );

    expect(
      decodedPaymentRequest.signature.fullSignature,
      equals(
        '6ca95a74dc32e69ced6175b15a5cc56a92bf19f5dace0f134b7d94d464b9f5cf6090a18d48b243f289394d17bdf89466d8e6b37df5981f696bc3dd5986e1bee1',
      ),
    );

    expect(
      decodedPaymentRequest.signature.rValue,
      equals(
        '6ca95a74dc32e69ced6175b15a5cc56a92bf19f5dace0f134b7d94d464b9f5cf',
      ),
    );

    expect(
      decodedPaymentRequest.signature.sValue,
      equals(
        '6090a18d48b243f289394d17bdf89466d8e6b37df5981f696bc3dd5986e1bee1',
      ),
    );

    expect(
      decodedPaymentRequest.signature.recoveryFlag,
      equals(1),
    );
  });

  test('should correctly parse lightning payment request with amount of zero', () {
    const paymentRequest =
        'lnbc1p3ew0wkpp5wcexslrr63jqvyfs7t5ezmnq3qgs9ccd5p5eraz0q4y7yh6akupsdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdgdwxf5j48jf5qqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldgdwxf5j48jf5qqqqqryqqqqthqqpysp5vr7uvzl0y00elhqp3erw3r0zmf04g96q4vwmq4cmnwl8axr9fx7q9qypqsqarzs9hjd9gm5p84sllx26hpukelfkzujx07dxgzdyffdfsugazq9gk6ds2l8eyr5fa574xyer249hcazcqvyeewr0yjy2r6j3258cfgqrurvr4';
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    expect(decodedPaymentRequest.amount, equals(0));
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

  test('should decode lightning payment request with 1 BTC', () {
    // lightning payment request with amount of 1 BTC
    const paymentRequest =
        'lnbc11p36kmlepp5etqkswemkuja22heq52paug5f3r7653svrzxsvvlnqde2ns804tqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhd35z2zn7evryeuqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ld35z2zn7evryeuqqqqryqqqqthqqpysp5gp4lt82grx4z594a8k0vrvpgkdnkpsz66gkaumcevfjvfk5vtcps9qypqsqyftazvgcjzj7us5w395pu320umfkwk5ff0mwg94lyvguwkrlqunr4dlms8qvuhzpq67rhxnm33u7chngdekw8zqw36h4rs7xt29kxlcqrgdfpv';

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    expect(decodedPaymentRequest.amount, equals(1));
  });

  test('should decode lightning payment request with large amount', () {
    // lightning payment request with amount of 20 BTC
    const paymentRequest =
        'lnbc201p36kmampp5kxm6ygjqt0suj0e0zdvtdf3rekpkwezxxfa2f0u5k5ndj3m6znesdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhded52hn9qpak7gqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3lded52hn9qpak7gqqqqryqqqqthqqpysp57tfffgzqjsc28xmys78y905txuup9ff9jt6vs8yrq3swlrdlgtcs9qypqsqwlqnmvhkplqef2auuqr8qegj3eqyupgjj3akqtwayuqm4rfarhfser53rznecj6th8cesa0j2rxlr0jw53kzhc3ugmq8kt6adut6zdspm74540';

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    expect(decodedPaymentRequest.amount, equals(20));
  });
}
