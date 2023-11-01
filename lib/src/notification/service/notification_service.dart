import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NotificationWalletService {
  NotificationWalletService();

  final StandardWalletService standardWalletService = StandardWalletService();

  SpendBundle createNotificationSpendBundle({
    required Puzzlehash targetPuzzlehash,
    required List<Memo> message,
    required int amount,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final notificationPuzzle =
        notificationProgram.curry([Program.fromBytes(targetPuzzlehash), Program.fromInt(amount)]);
    final notificationPuzzlehash = notificationPuzzle.hash();

    final originCoin = originId != null
        ? coinsInput.where((coin) => coin.id == originId).toList().single
        : coinsInput.first;

    final notificationCoin = CoinPrototype(
      parentCoinInfo: originCoin.id,
      puzzlehash: notificationPuzzlehash,
      amount: amount,
    );

    final notificationCoinSpend = CoinSpend(
      coin: notificationCoin,
      puzzleReveal: notificationPuzzle,
      solution: Program.nil,
    );

    final notificationSpendBundle = SpendBundle(coinSpends: [notificationCoinSpend]);

    final messageCoinAnnouncement = AssertCoinAnnouncementCondition(notificationCoin.id, Bytes([]));

    final standardSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          amount,
          notificationPuzzlehash,
          memos: <Memo>[
            Memo(targetPuzzlehash),
            ...message,
          ],
        )
      ],
      coinsInput: coinsInput,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: [messageCoinAnnouncement, ...coinAnnouncementsToAssert],
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final totalSpendBundle = notificationSpendBundle + standardSpendBundle;
    return totalSpendBundle;
  }
}
