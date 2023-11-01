import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class SpendCatCommand implements WalletConnectCommand {
  const SpendCatCommand({
    required this.walletId,
    required this.address,
    required this.amount,
    required this.fee,
    this.waitForConfirmation = false,
    this.memos = const [],
  });
  factory SpendCatCommand.fromParams(Map<String, dynamic> params) {
    return SpendCatCommand(
      walletId: pick(params, 'walletId').asIntOrThrow(),
      address: Address(pick(params, 'address').asStringOrThrow()),
      amount: pick(params, 'amount').asIntOrThrow(),
      fee: pick(params, 'fee').asIntOrThrow(),
      waitForConfirmation: pick(params, 'waitForConfirmation').asBoolOrFalse(),
      memos:
          pick(params, 'memos').letStringListOrNull((string) => string) ?? [],
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.spendCAT;

  final int walletId;
  final Address address;
  final int amount;
  final int fee;
  final bool waitForConfirmation;
  final List<String> memos;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'walletId': walletId,
      'address': address.address,
      'amount': amount,
      'fee': fee,
      'memos': memos,
    };
  }
}
