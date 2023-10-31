import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetNextAddressCommand implements WalletConnectCommand {
  const GetNextAddressCommand({
    this.walletId = 1,
    this.newAddress = true,
  });
  factory GetNextAddressCommand.fromParams(Map<String, dynamic> params) {
    return GetNextAddressCommand(
      walletId: pick(params, 'walletId').asIntOrNull(),
      newAddress: pick(params, 'newAddress').asBoolOrNull(),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getNextAddress;

  final int? walletId;
  final bool? newAddress;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'walletId': walletId, 'newAddress': newAddress};
  }
}

class GetAddressResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetAddressResponse(this.delegate, this.address);
  factory GetAddressResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final addressData = pick(json, 'data').letStringOrThrow(Address.new);
    return GetAddressResponse(baseResponse, addressData);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final Address address;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': address.address,
    };
  }
}
