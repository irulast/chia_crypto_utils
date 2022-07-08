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
  }) async {
    final response = await sendXchWithPayments(
      coins: coins,
      payments: [Payment(amount, puzzlehash)],
      fee: fee,
      changePuzzlehash: changePuzzlehash,
    );
    return response;
  }

  Future<ChiaBaseResponse> sendXchWithPayments({
    required List<Coin> coins,
    required List<Payment> payments,
    int fee = 0,
    Puzzlehash? changePuzzlehash,
  }) async {
    final changePuzzlehashToUse = changePuzzlehash ?? keychain.puzzlehashes.first;
    final spendBundle = walletService.createSpendBundle(
      payments: payments,
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehashToUse,
      fee: fee,
    );
    final response = await fullNode.pushTransaction(spendBundle);
    return response;
  }
}
