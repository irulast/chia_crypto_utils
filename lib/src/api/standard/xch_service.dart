import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/namesdao/exceptions/invalid_namesdao_name.dart';

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

  Future<ChiaBaseResponse?> sendXchToNamesdao({
    required List<Coin> coins,
    required int amount,
    required String namesdaoName,
    int fee = 0,
    Puzzlehash? changePuzzlehash,
    required NamesdaoApi namesdaoApi,
  }) async {
    final nameInfo = await namesdaoApi.getNameInfo(namesdaoName);

    if (nameInfo == null) {
      throw InvalidNamesdaoName();
    } else {
      final puzzlehash = nameInfo.address.toPuzzlehash();
      final response = await sendXch(coins: coins, amount: amount, puzzlehash: puzzlehash);
      return response;
    }
  }
}
