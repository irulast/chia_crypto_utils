import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';
import 'package:test/test.dart';

void main() {
  test('should correctly serialize and deserialize XCH to BTC offer file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    const offeredAmount = ExchangeAmount(type: 'XCH', amount: 1000);

    const requestedAmount = ExchangeAmount(type: 'BTC', amount: 1);

    const messageAddress =
        Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');

    final publicKey = privateKey.getG1();

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerFile = XchToBtcOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      publicKey: publicKey,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, privateKey);
    final deserializedOfferFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as XchToBtcOfferFile;

    expect(deserializedOfferFile.offeredAmount, equals(offeredAmount));
    expect(deserializedOfferFile.requestedAmount, equals(requestedAmount));
    expect(deserializedOfferFile.messageAddress, equals(messageAddress));
    expect(deserializedOfferFile.publicKey, equals(publicKey));
    expect(
      deserializedOfferFile.lightningPaymentRequest.paymentRequest,
      decodedPaymentRequest.paymentRequest,
    );
  });
}
