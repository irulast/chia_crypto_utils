import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetWalletBalanceCommand implements WalletConnectCommand {
  const GetWalletBalanceCommand({this.walletId = 1});
  factory GetWalletBalanceCommand.fromParams(Map<String, dynamic> params) {
    return GetWalletBalanceCommand(walletId: pick(params, 'walletId').asIntOrNull());
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getWalletBalance;

  final int? walletId;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'walletId': walletId};
  }
}

class GetWalletBalanceResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetWalletBalanceResponse(this.delegate, this.balance);
  factory GetWalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final balance = WalletBalance.fromJson(pick(json, 'data').letJsonOrThrow((json) => json));
    return GetWalletBalanceResponse(baseResponse, balance);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final WalletBalance balance;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': balance.toJson(),
    };
  }
}

class WalletBalance {
  const WalletBalance({
    required this.confirmedWalletBalance,
    required this.fingerprint,
    required this.maxSendAmount,
    required this.pendingChange,
    required this.pendingCoinRemovalCount,
    required this.spendableBalance,
    required this.unconfirmedWalletBalance,
    required this.unspentCoinCount,
    required this.walletId,
    required this.walletType,
  });
  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      confirmedWalletBalance: pick(json, 'confirmedWalletBalance').asIntOrThrow(),
      fingerprint: pick(json, 'fingerprint').asIntOrThrow(),
      maxSendAmount: pick(json, 'maxSendAmount').asIntOrThrow(),
      pendingChange: pick(json, 'pendingChange').asIntOrThrow(),
      pendingCoinRemovalCount: pick(json, 'pendingCoinRemovalCount').asIntOrThrow(),
      spendableBalance: pick(json, 'spendableBalance').asIntOrThrow(),
      unconfirmedWalletBalance: pick(json, 'unconfirmedWalletBalance').asIntOrThrow(),
      unspentCoinCount: pick(json, 'unspentCoinCount').asIntOrThrow(),
      walletId: pick(json, 'walletId').asIntOrThrow(),
      walletType: ChiaWalletType.fromIndex(pick(json, 'walletType').asIntOrThrow()),
    );
  }

  final int confirmedWalletBalance;
  final int fingerprint;
  final int maxSendAmount;
  final int pendingChange;
  final int pendingCoinRemovalCount;
  final int spendableBalance;
  final int unconfirmedWalletBalance;
  final int unspentCoinCount;
  final int walletId;
  final ChiaWalletType walletType;

  Map<String, dynamic> toJson() {
    return {
      'confirmedWalletBalance': confirmedWalletBalance,
      'fingerprint': fingerprint,
      'maxSendAmount': maxSendAmount,
      'pendingChange': pendingChange,
      'pendingCoinRemovalCount': pendingCoinRemovalCount,
      'spendableBalance': spendableBalance,
      'unconfirmedWalletBalance': unconfirmedWalletBalance,
      'unspentCoinCount': unspentCoinCount,
      'walletId': walletId,
      'walletType': walletType.index,
    };
  }
}
