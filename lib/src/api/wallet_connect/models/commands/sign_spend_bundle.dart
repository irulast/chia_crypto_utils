import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class SignSpendBundleCommand implements WalletConnectCommand {
  const SignSpendBundleCommand({
    required this.spendBundle,
  });
  factory SignSpendBundleCommand.fromParams(Map<String, dynamic> params) {
    return SignSpendBundleCommand(
      spendBundle:
          pick(params, 'spendBundle').letJsonOrThrow(SpendBundle.fromJson),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.signSpendBundle;

  final SpendBundle spendBundle;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'spendBundle': spendBundle.toJson()};
  }
}

class SignSpendBundleResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const SignSpendBundleResponse(this.delegate, this.signature);
  factory SignSpendBundleResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final signature =
        pick(json, 'data').letStringOrThrow(JacobianPoint.fromHexG2);

    return SignSpendBundleResponse(baseResponse, signature);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;

  final JacobianPoint signature;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': signature.toHex(),
    };
  }
}
