import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class AddCatTokenCommand implements WalletConnectCommand {
  const AddCatTokenCommand({
    required this.assetId,
    required this.name,
  });
  factory AddCatTokenCommand.fromParams(Map<String, dynamic> params) {
    return AddCatTokenCommand(
      assetId: Puzzlehash.fromHex(pick(params, 'assetId').asStringOrThrow()),
      name: pick(params, 'name').asStringOrThrow(),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.addCATToken;

  final Puzzlehash assetId;
  final String name;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'assetId': assetId.toHex(),
      'name': name,
    };
  }
}

class AddCatTokenResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const AddCatTokenResponse(this.delegate, this.walletId);
  factory AddCatTokenResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    return AddCatTokenResponse(baseResponse, pick(json, 'data').asIntOrThrow());
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final int walletId;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': walletId,
    };
  }
}
