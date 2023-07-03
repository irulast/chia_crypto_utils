import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetCurrentAddressCommand implements WalletConnectCommand {
  const GetCurrentAddressCommand({
    this.walletId = 1,
  });

  factory GetCurrentAddressCommand.fromParams(Map<String, dynamic> params) {
    return GetCurrentAddressCommand(walletId: pick(params, 'walletId').asIntOrNull());
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getCurrentAddress;

  final int? walletId;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'walletId': walletId,
    };
  }
}
