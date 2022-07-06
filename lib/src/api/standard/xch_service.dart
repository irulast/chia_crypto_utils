import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class XchService {
  XchService({
    required this.fullNode,
    required this.keychain,
  });
  final ChiaFullNodeInterface fullNode;
  final WalletKeychain keychain;

  StandardWalletService get walletService => StandardWalletService();

  Future<ChiaBaseResponse> sendXch({
    required List<Coin> coins,
    required int amount,
    required Puzzlehash puzzlehash,
    int fee = 0,
    Puzzlehash? changePuzzlehash,
    CoinSelector? coinSelector = selectCoinsForAmount,
  }) {
    return sendXchWithPayments(
      coins: coins,
      payments: [Payment(amount, puzzlehash)],
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      coinSelector: coinSelector,
    );
  }

  Future<ChiaBaseResponse> sendXchWithPayments({
    required List<Coin> coins,
    required List<Payment> payments,
    int fee = 0,
    Puzzlehash? changePuzzlehash,
    CoinSelector? coinSelector = selectCoinsForAmount,
  }) {
    final coinsToUse = (coinSelector != null) ? coinSelector(coins, payments.totalValue) : coins;

    final changePuzzlehashToUse = changePuzzlehash ?? keychain.puzzlehashes.first;
    final spendBundle = walletService.createSpendBundle(
      payments: payments,
      coinsInput: coinsToUse,
      keychain: keychain,
      changePuzzlehash: changePuzzlehashToUse,
      fee: fee,
    );
    return fullNode.pushTransaction(spendBundle);
  }
}
