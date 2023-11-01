import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class LogInCommand implements WalletConnectCommand {
  const LogInCommand({
    required this.fingerprint,
  });
  factory LogInCommand.fromParams(Map<String, dynamic> params) {
    return LogInCommand(fingerprint: pick(params, 'fingerprint').asIntOrThrow());
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.logIn;

  final int fingerprint;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'fingerprint': fingerprint};
  }
}

class LogInResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const LogInResponse(this.delegate, this.logInData);
  factory LogInResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    return LogInResponse(baseResponse, pick(json, 'data').letJsonOrThrow(LogInData.fromJson));
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final LogInData logInData;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': logInData.toJson(),
    };
  }
}

class LogInData with ToJsonMixin {
  const LogInData({required this.fingerprint, required this.success});
  factory LogInData.fromJson(Map<String, dynamic> json) {
    return LogInData(
      fingerprint: pick(json, 'fingerprint').asIntOrThrow(),
      success: pick(json, 'success').asBoolOrThrow(),
    );
  }

  final int fingerprint;
  final bool success;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fingerprint': fingerprint,
      'success': success,
    };
  }
}
