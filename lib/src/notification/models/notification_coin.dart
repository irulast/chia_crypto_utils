import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NotificationCoin with CoinPrototypeDecoratorMixin implements Coin {
  NotificationCoin({
    required this.delegate,
    required this.targetPuzzlehash,
    required this.message,
  });

  @override
  final Coin delegate;
  final Puzzlehash targetPuzzlehash;
  final List<Memo> message;

  static Future<NotificationCoin?> maybeFromParentSpend({
    required CoinSpend parentCoinSpend,
    required Coin coin,
  }) async {
    final memos = await parentCoinSpend.memos;
    if (memos.length < 2) return null;
    final targetPuzzlehash = Puzzlehash(memos.first);
    final message = memos.sublist(1);

    return NotificationCoin(delegate: coin, targetPuzzlehash: targetPuzzlehash, message: message);
  }

  static Future<NotificationCoin> fromParentSpend({
    required CoinSpend parentCoinSpend,
    required Coin coin,
  }) async {
    final notificationCoin = await maybeFromParentSpend(
      parentCoinSpend: parentCoinSpend,
      coin: coin,
    );

    if (notificationCoin == null) {
      throw InvalidNotificationCoinException();
    }
    return notificationCoin;
  }

  @override
  bool get coinbase => delegate.coinbase;

  @override
  int get confirmedBlockIndex => delegate.confirmedBlockIndex;

  @override
  int get spentBlockIndex => delegate.spentBlockIndex;

  @override
  int get timestamp => delegate.timestamp;

  @override
  Map<String, dynamic> toFullJson() {
    return delegate.toFullJson();
  }
}
