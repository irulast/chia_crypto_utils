import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';

class XchToBtcService {
  final BtcExchangeService exchangeService = BtcExchangeService();

  Puzzlehash generateChiaswapPuzzlehash({
    required PrivateKey requestorPrivateKey,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();

    final chiaswapPuzzle = exchangeService.generateChiaswapPuzzle(
      clawbackPublicKey: requestorPublicKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      sweepPublicKey: fulfillerPublicKey,
    );

    return chiaswapPuzzle.hash();
  }

  SpendBundle createClawbackSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required PrivateKey requestorPrivateKey,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 10,
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
      requestorPrivateKey: requestorPrivateKey,
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

  SpendBundle createClawbackSpendBundleWithPk({
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
          clawbackPublicKey: requestorPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: fulfillerPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        final hiddenPuzzle = exchangeService.generateHiddenPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: requestorPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: fulfillerPublicKey,
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

  Puzzlehash generateChiaswapPuzzlehashFromKeychain({
    required WalletKeychain requestorKeychain,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPrivateKey = walletVector.childPrivateKey;

    return generateChiaswapPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );
  }

  SpendBundle createClawbackSpendBundleFromKeychain({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPrivateKey = walletVector.childPrivateKey;

    return createClawbackSpendBundle(
      payments: payments,
      coinsInput: coinsInput,
      requestorPrivateKey: requestorPrivateKey,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );
  }

  SpendBundle createClawbackSpendBundleWithPkFromKeychain({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 10,
    required Bytes sweepPaymentHash,
    required PrivateKey fulfillerPrivateKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPrivateKey = walletVector.childPrivateKey;

    return createClawbackSpendBundleWithPk(
      payments: payments,
      coinsInput: coinsInput,
      requestorPrivateKey: requestorPrivateKey,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPrivateKey: fulfillerPrivateKey,
    );
  }
}
