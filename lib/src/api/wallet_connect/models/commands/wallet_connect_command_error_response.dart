import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class WalletConnectCommandErrorResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const WalletConnectCommandErrorResponse(this.delegate, this.error);

  @override
  final WalletConnectCommandBaseResponse delegate;
  final String error;

  factory WalletConnectCommandErrorResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final error = pick(json, 'error').letStringOrThrow((string) => string);

    return WalletConnectCommandErrorResponse(baseResponse, error);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'error': error,
    };
  }
}
