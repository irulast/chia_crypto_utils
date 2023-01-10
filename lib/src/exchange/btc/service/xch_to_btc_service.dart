import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class XchToBtcService {
  XchToBtcService(this.fullNode);
  final ChiaFullNodeInterface fullNode;
  final BtcExchangeService exchangeService = BtcExchangeService();
  final BaseWalletService baseWalletService = BaseWalletService();
  final StandardWalletService standardWalletService = StandardWalletService();

  static Puzzlehash generateEscrowPuzzlehash({
    required PrivateKey requestorPrivateKey,
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();

    final escrowPuzzle = BtcExchangeService.generateEscrowPuzzle(
      clawbackPublicKey: requestorPublicKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      sweepPublicKey: fulfillerPublicKey,
    );

    return escrowPuzzle.hash();
  }

  SpendBundle createClawbackSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required PrivateKey requestorPrivateKey,
    Puzzlehash? changePuzzlehash,
    required int clawbackDelaySeconds,
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
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required PrivateKey fulfillerPrivateKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final requestorPublicKey = requestorPrivateKey.getG1();
    final fulfillerPublicKey = fulfillerPrivateKey.getG1();

    return baseWalletService.createSpendBundleBase(
      payments: payments,
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      makePuzzleRevealFromPuzzlehash: (puzzlehash) {
        return BtcExchangeService.generateEscrowPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: requestorPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: fulfillerPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        final hiddenPuzzle = BtcExchangeService.generateHiddenPuzzle(
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

        return baseWalletService.makeSignature(
          totalPrivateKey,
          coinSpend,
          useSyntheticOffset: false,
        );
      },
    );
  }

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
      changePuzzlehash: changePuzzlehash,
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

    final clawbackSpendBundle = createClawbackSpendBundle(
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
