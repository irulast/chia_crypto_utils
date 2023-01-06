import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';

class BtcToXchCrossChainOfferService {
  BtcToXchCrossChainOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final standardWalletService = StandardWalletService();

  final btcToXchService = BtcToXchService();

  Future<void> pushSweepSpendbundle({
    required Puzzlehash escrowPuzzlehash,
    required Puzzlehash sweepPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required int validityTime,
    required Bytes paymentHash,
    required Bytes preimage,
    required JacobianPoint fulfillerPublicKey,
  }) async {
    final escrowCoins = await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
      payments: [Payment(escrowCoins.totalValue, sweepPuzzlehash)],
      coinsInput: escrowCoins,
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: validityTime,
      sweepPaymentHash: paymentHash,
      sweepPreimage: preimage,
      fulfillerPublicKey: fulfillerPublicKey,
    );

    await fullNode.pushTransaction(sweepSpendBundle);
  }
}
