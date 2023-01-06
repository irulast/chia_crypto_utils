import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie_post_offer_response.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_accept_file.dart';
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

  CrossChainOfferFile makeCrossChainOfferFile({
    required int amountMojos,
    required int amountSatoshis,
    required Address messageAddress,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
    LightningPaymentRequest? paymentRequest,
  }) {
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

    return offerFile;
  }

  Future<DexiePostOfferResponse> postCrossChainOfferFileToDexie(
    CrossChainOfferFile offerFile,
    PrivateKey requestorPrivateKey,
  ) async {
    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, requestorPrivateKey);
    final response = await dexieApi.postOffer(serializedOfferFile);
    return response;
  }

  Future<CrossChainOfferAcceptFile?> getOfferAcceptFileFromMessagePuzzlehash(
    Puzzlehash messagePuzzlehash,
    String serializedOfferFile,
  ) async {
    final coins = await fullNode.getCoinsByPuzzleHashes(
      [messagePuzzlehash],
    );

    for (final coin in coins) {
      final parentCoin = await fullNode.getCoinById(coin.parentCoinInfo);
      final coinSpend = await fullNode.getCoinSpend(parentCoin!);
      final memos = await coinSpend!.memoStrings;

      for (final memo in memos) {
        if (memo.startsWith('ccoffer_accept')) {
          try {
            final deserializedMemo =
                deserializeCrossChainOfferFile(memo) as CrossChainOfferAcceptFile;
            if (deserializedMemo.acceptedOfferHash ==
                Bytes.encodeFromString(serializedOfferFile).sha256Hash()) return deserializedMemo;
          } catch (e) {
            continue;
          }
        }
      }
    }
    return null;
  }
}
