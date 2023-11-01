import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetNftsCountCommand implements WalletConnectCommand {
  const GetNftsCountCommand({
    required this.walletIds,
  });
  factory GetNftsCountCommand.fromParams(Map<String, dynamic> params) {
    return GetNftsCountCommand(
      walletIds: pick(params, 'walletIds')
          .asListOrThrow<int>((json) => json.asIntOrThrow()),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getNFTsCount;

  final List<int> walletIds;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'walletIds': walletIds};
  }
}

class GetNftCountResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetNftCountResponse(this.delegate, this.countData);
  factory GetNftCountResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final countData = pick(json, 'data').asMapOrThrow<String, int>();

    return GetNftCountResponse(baseResponse, countData);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;

  final Map<String, int> countData;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': countData,
    };
  }

  int get total => pick(countData, 'total').asIntOrThrow();
}
