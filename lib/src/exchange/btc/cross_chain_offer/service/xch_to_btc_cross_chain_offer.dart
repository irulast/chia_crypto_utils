import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';

class XchToBtcCrossChainOfferService {
  XchToBtcCrossChainOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final standardWalletService = StandardWalletService();
  final xchToBtcService = XchToBtcService();

  Future<void> sendXchToEscrowPuzzlehash({
    required int amount,
    required Puzzlehash escrowPuzzlehash,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
  }) async {
    final escrowSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(amount, escrowPuzzlehash)],
      coinsInput: coinsInput,
      keychain: keychain,
      fee: fee,
    );

    await fullNode.pushTransaction(escrowSpendBundle);
  }

  Future<void> pushClawbackSpendBundle({
    required Puzzlehash escrowPuzzlehash,
    required Puzzlehash clawbackPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required int validityTime,
    required Bytes paymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) async {
    final escrowCoins = await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
      payments: [Payment(escrowCoins.totalValue, clawbackPuzzlehash)],
      coinsInput: escrowCoins,
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: validityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );

    await fullNode.pushTransaction(clawbackSpendBundle);
  }
}
