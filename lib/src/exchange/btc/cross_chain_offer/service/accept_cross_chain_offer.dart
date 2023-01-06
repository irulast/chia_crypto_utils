import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie_post_offer_response.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_accept_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';

class AcceptCrossChainOfferService {
  AcceptCrossChainOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final standardWalletService = StandardWalletService();

  String createCrossChainOfferAcceptFile({
    required String serializedOfferFile,
    required int validityTime,
    required PrivateKey requestorPrivateKey,
    LightningPaymentRequest? paymentRequest,
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();

    final acceptedOfferHash = Bytes.encodeFromString(serializedOfferFile).sha256Hash();

    CrossChainOfferAcceptFile? offerAcceptFile;

    if (paymentRequest != null) {
      offerAcceptFile = XchToBtcOfferAcceptFile(
        validityTime: validityTime,
        publicKey: requestorPublicKey,
        lightningPaymentRequest: paymentRequest,
        acceptedOfferHash: acceptedOfferHash,
      );
    } else {
      offerAcceptFile = BtcToXchOfferAcceptFile(
        validityTime: validityTime,
        publicKey: requestorPublicKey,
        acceptedOfferHash: acceptedOfferHash,
      );
    }

    return serializeCrossChainOfferFile(offerAcceptFile, requestorPrivateKey);
  }

  Future<void> sendMessageCoin({
    required WalletKeychain keychain,
    required List<Coin> coinsInput,
    required Puzzlehash messagePuzzlehash,
    required String serializedOfferAcceptFile,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
  }) async {
    final messageSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(50, messagePuzzlehash, memos: <String>[serializedOfferAcceptFile])
      ],
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
    );

    await fullNode.pushTransaction(messageSpendBundle);
  }
}
