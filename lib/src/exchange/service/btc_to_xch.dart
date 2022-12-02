import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/service/exchange.dart';

class BtcToXchService {
  final BtcExchangeService exchangeService = BtcExchangeService();

  Address generateChiaswapPuzzleAddress({
    required WalletKeychain requestorKeychain,
    int clawbackDelaySeconds = 86400,
    required Puzzlehash sweepPuzzlehash,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPublicKey = walletVector.childPublicKey;

    final chiaswapPuzzle = exchangeService.generateChiaswapPuzzle(
      clawbackPublicKey: fulfillerPublicKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: requestorPublicKey,
    );

    return Address.fromContext(chiaswapPuzzle.hash());
  }

  SpendBundle createSweepSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 86400,
    required Puzzlehash sweepReceiptHash,
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
      requestorKeychain: requestorKeychain,
      changePuzzlehash: changePuzzlehash,
      clawbackDelaySeconds: clawbackDelaySeconds,
      fulfillerPublicKey: fulfillerPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPreimage: sweepPreimage,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );
  }

  // WARNING: this method effectively burns the private key and/or keychain associated with coin 
  // that is exposed to the external party. 
  
  SpendBundle createSweepSpendBundleWithPk({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    int clawbackDelaySeconds = 86400,
    required Puzzlehash sweepReceiptHash,
    required PrivateKey fulfillerPrivateKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPrivateKey = walletVector.childPrivateKey;
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
          sweepReceiptHash: sweepReceiptHash,
          sweepPublicKey: requestorPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        final hiddenPuzzle = exchangeService.generateHiddenPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: fulfillerPublicKey,
          sweepReceiptHash: sweepReceiptHash,
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
