import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class SignMessageByAddressCommand implements WalletConnectCommand {
  const SignMessageByAddressCommand({required this.address, required this.message});

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.signMessageByAddress;

  final Address address;
  final String message;

  factory SignMessageByAddressCommand.fromParams(Map<String, dynamic> params) {
    return SignMessageByAddressCommand(
      address: Address(pick(params, 'address').asStringOrThrow()),
      message: pick(params, 'message').asStringOrThrow(),
    );
  }

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'address': address.address, 'message': message};
  }
}

// Chia Lite Wallet only responds with data field for this command
class SignMessageByAddressResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const SignMessageByAddressResponse(
    this.delegate,
    this.signData,
  );

  @override
  final WalletConnectCommandBaseResponse delegate;
  final SignMessageByAddressData signData;

  factory SignMessageByAddressResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    return SignMessageByAddressResponse(
      baseResponse,
      pick(json, 'data').letJsonOrThrow(SignMessageByAddressData.fromJson),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...delegate.toJson(),
      'data': signData.toJson(),
    };
  }
}

class SignMessageByAddressData {
  const SignMessageByAddressData({
    required this.publicKey,
    required this.signature,
    required this.signingMode,
    required this.success,
  });

  final JacobianPoint publicKey;
  final JacobianPoint signature;
  final SigningMode signingMode;
  final bool success;

  factory SignMessageByAddressData.fromJson(Map<String, dynamic> json) {
    return SignMessageByAddressData(
      publicKey: JacobianPoint.fromHexG1(pick(json, 'pubkey').asStringOrThrow()),
      signature: JacobianPoint.fromHexG2(pick(json, 'signature').asStringOrThrow()),
      signingMode: SigningMode.fromString(pick(json, 'signingMode').asStringOrThrow()),
      success: pick(json, 'success').asBoolOrThrow(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pubkey': publicKey.toHex(),
      'signature': signature.toHex(),
      'signingMode': signingMode.fullName,
      'success': success,
    };
  }
}
