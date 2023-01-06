import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie_post_offer_response.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';

class CrossChainOfferService {
  CrossChainOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final DexieApi dexieApi = DexieApi();
  final standardWalletService = StandardWalletService();

  String makeCrossChainOfferFile({
    required int amountMojos,
    required int amountSatoshis,
    required Address messageAddress,
    required int validityTime,
    required PrivateKey requestorPrivateKey,
    LightningPaymentRequest? paymentRequest,
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();

    CrossChainOfferFile? offerFile;
    if (paymentRequest != null) {
      final offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos);
      final requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis);

      offerFile = XchToBtcOfferFile(
        offeredAmount: offeredAmount,
        requestedAmount: requestedAmount,
        messageAddress: messageAddress,
        validityTime: validityTime,
        publicKey: requestorPublicKey,
        lightningPaymentRequest: paymentRequest,
      );
    } else {
      final offeredAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis);
      final requestedAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos);

      offerFile = BtcToXchOfferFile(
        offeredAmount: offeredAmount,
        requestedAmount: requestedAmount,
        messageAddress: messageAddress,
        validityTime: validityTime,
        publicKey: requestorPublicKey,
      );
    }

    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, requestorPrivateKey);

    return serializedOfferFile;
  }

  Future<DexiePostOfferResponse> postCrossChainOfferFileToDexie(String serializedOfferFile) async {
    final response = await dexieApi.postOffer(serializedOfferFile);
    return response;
  }
}
