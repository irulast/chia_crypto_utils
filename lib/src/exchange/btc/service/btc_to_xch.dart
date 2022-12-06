import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';

class BtcToXchService {
  final BtcExchangeService exchangeService = BtcExchangeService();

  Puzzlehash generateChiaswapPuzzlehash({
    required PrivateKey requestorPrivateKey,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();

    final chiaswapPuzzle = exchangeService.generateChiaswapPuzzle(
      clawbackPublicKey: fulfillerPublicKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      sweepPublicKey: requestorPublicKey,
    );

    return chiaswapPuzzle.hash();
  }

  SpendBundle createSweepSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required PrivateKey requestorPrivateKey,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
    required Bytes sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return exchangeService.createExchangeSpendBundle(
      payments: payments,
      coinsInput: coinsInput,
      requestorPrivateKey: requestorPrivateKey,
      changePuzzlehash: changePuzzlehash,
      clawbackDelaySeconds: clawbackDelaySeconds,
      fulfillerPublicKey: fulfillerPublicKey,
      sweepPaymentHash: sweepPaymentHash,
      sweepPreimage: sweepPreimage,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );
  }

  SpendBundle createSweepSpendBundleWithPk({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required PrivateKey requestorPrivateKey,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required PrivateKey fulfillerPrivateKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();
    final fulfillerPublicKey = fulfillerPrivateKey.getG1();

    return BaseWalletService().createSpendBundleBase(
      payments: payments,
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      makePuzzleRevealFromPuzzlehash: (puzzlehash) {
        return exchangeService.generateChiaswapPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: fulfillerPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: requestorPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        final hiddenPuzzle = exchangeService.generateHiddenPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: fulfillerPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: requestorPublicKey,
        );

        final totalPublicKey = requestorPublicKey + fulfillerPublicKey;

        final totalPrivateKey = calculateTotalPrivateKey(
          totalPublicKey,
          hiddenPuzzle,
          requestorPrivateKey,
          fulfillerPrivateKey,
        );

        return BaseWalletService()
            .makeSignature(totalPrivateKey, coinSpend, useSyntheticOffset: false);
      },
    );
  }
}
