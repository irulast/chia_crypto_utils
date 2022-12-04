import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';

class XchToBtcService {
  final BtcExchangeService exchangeService = BtcExchangeService();

  Address generateChiaswapPuzzleAddress({
    required WalletKeychain requestorKeychain,
    int clawbackDelaySeconds = 86400,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPublicKey = walletVector.childPublicKey;

    final chiaswapPuzzle = exchangeService.generateChiaswapPuzzle(
      clawbackPublicKey: requestorPublicKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      sweepPublicKey: fulfillerPublicKey,
    );

    return Address.fromContext(chiaswapPuzzle.hash());
  }

  SpendBundle createClawbackSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 86400,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return exchangeService.createExchangeSpendBundle(
      payments: payments,
      coinsInput: coinsInput,
      requestorKeychain: requestorKeychain,
      changePuzzlehash: changePuzzlehash,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );
  }
}
