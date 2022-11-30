import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/service/exchange.dart';

class BtcToXchExchangeService {
  final BtcExchangeService exchangeService = BtcExchangeService();

  Puzzlehash generateHoldingAddressPuzzlehash({
    required int clawbackDelaySeconds,
    required JacobianPoint counterpartyPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint myPublicKey,
  }) {
    final holdingAddressPuzzle = exchangeService.generateHoldingAddressPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: counterpartyPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: myPublicKey,
    );

    return holdingAddressPuzzle.hash();
  }

  SpendBundle createSweepSpendBundleWithPreimage({
    required int amount,
    required Address sweepAddress,
    required List<CoinPrototype> holdingAddressCoins,
    required int clawbackDelaySeconds,
    required PrivateKey myPrivateKey,
    required JacobianPoint myPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint counterpartyPublicKey,
    required Bytes sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return exchangeService.createExchangeSpendBundle(
      payments: [Payment(amount, sweepAddress.toPuzzlehash())],
      coinsInput: holdingAddressCoins,
      clawbackDelaySeconds: clawbackDelaySeconds,
      privateKey: myPrivateKey,
      clawbackPublicKey: counterpartyPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: myPublicKey,
      sweepPreimage: sweepPreimage,
    );
  }

  SpendBundle createSweepSpendBundleWithPk({
    required int amount,
    required Address sweepAddress,
    required List<CoinPrototype> holdingAddressCoins,
    required int clawbackDelaySeconds,
    required PrivateKey myPrivateKey,
    required JacobianPoint myPublicKey,
    required Puzzlehash sweepReceiptHash,
    required PrivateKey counterpartyPrivateKey,
    required JacobianPoint counterpartyPublicKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return BaseWalletService().createSpendBundleBase(
      payments: [Payment(amount, sweepAddress.toPuzzlehash())],
      coinsInput: holdingAddressCoins,
      makePuzzleRevealFromPuzzlehash: (puzzlehash) {
        return exchangeService.generateHoldingAddressPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: counterpartyPublicKey,
          sweepReceiptHash: sweepReceiptHash,
          sweepPublicKey: myPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        final hiddenPuzzle = exchangeService.generateHiddenPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: counterpartyPublicKey,
          sweepReceiptHash: sweepReceiptHash,
          sweepPublicKey: myPublicKey,
        );

        final totalPublicKey = myPublicKey + counterpartyPublicKey;

        final totalPrivateKey = calculateTotalPrivateKey(
          totalPublicKey,
          hiddenPuzzle,
          myPrivateKey,
          counterpartyPrivateKey,
        );

        return BaseWalletService()
            .makeSignature(totalPrivateKey, coinSpend, useSyntheticOffset: false);
      },
    );
  }
}
