import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';

class CrossChainOfferExchangeInfo {
  CrossChainOfferExchangeInfo({
    required this.amountMojos,
    required this.amountSatoshis,
    required this.escrowPuzzlehash,
    required this.paymentRequest,
  });

  int amountMojos;
  int amountSatoshis;
  Puzzlehash escrowPuzzlehash;
  LightningPaymentRequest paymentRequest;
}
