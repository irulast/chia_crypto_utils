import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetWalletsCommand implements WalletConnectCommand {
  const GetWalletsCommand({
    this.includeData = false,
  });

  factory GetWalletsCommand.fromParams(Map<String, dynamic> params) {
    return GetWalletsCommand(includeData: pick(params, 'includeData').asBoolOrFalse());
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getWallets;

  final bool includeData;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'includeData': includeData};
  }
}

class GetWalletsResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetWalletsResponse(this.delegate, this.wallets);

  factory GetWalletsResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final wallets = pick(json, 'data').letJsonListOrThrow(ChiaWalletInfoImp.fromJson);

    return GetWalletsResponse(baseResponse, wallets);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final List<ChiaWalletInfo> wallets;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...delegate.toJson(),
      'data': wallets.map((wallet) => wallet.toJson()).toList(),
    };
  }
}
