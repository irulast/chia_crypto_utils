import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';

class CrossChainOfferExchangeInfo {
  CrossChainOfferExchangeInfo({
    required this.requestorPublicKey,
    required this.fulfillerPublicKey,
    required this.amountMojos,
    required this.amountSatoshis,
    required this.validityTime,
    required this.escrowPuzzlehash,
    required this.paymentRequest,
  });

  JacobianPoint requestorPublicKey;
  JacobianPoint fulfillerPublicKey;
  int amountMojos;
  int amountSatoshis;
  int validityTime;
  Puzzlehash escrowPuzzlehash;
  LightningPaymentRequest paymentRequest;

  Bytes? get paymentHash => paymentRequest.tags.paymentHash;
}
