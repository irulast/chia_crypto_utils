import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/service/exchange.dart';

class XchToBtcExchangeService {
  final BtcExchangeService exchangeService = BtcExchangeService();

  Puzzlehash generateHoldingAddressPuzzlehash({
    required int clawbackDelaySeconds,
    required JacobianPoint myPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint counterpartyPublicKey,
  }) {
    final holdingAddressPuzzle = exchangeService.generateHoldingAddressPuzzle(
      clawbackPublicKey: myPublicKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: counterpartyPublicKey,
    );

    return holdingAddressPuzzle.hash();
  }

  SpendBundle createClawbackSpendBundle({
    required int amount,
    required Address clawbackAddress,
    required List<CoinPrototype> holdingAddressCoins,
    required int clawbackDelaySeconds,
    required PrivateKey myPrivateKey,
    required JacobianPoint myPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint counterpartyPublicKey,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return exchangeService.createExchangeSpendBundle(
      payments: [Payment(amount, clawbackAddress.toPuzzlehash())],
      coinsInput: holdingAddressCoins,
      clawbackDelaySeconds: clawbackDelaySeconds,
      privateKey: myPrivateKey,
      clawbackPublicKey: myPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: counterpartyPublicKey,
    );
  }
}
