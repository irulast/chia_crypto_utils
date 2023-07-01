import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class SignMessageByIdCommand implements WalletConnectCommand {
  const SignMessageByIdCommand({required this.id, required this.message});

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.signMessageById;

  final Bytes id;
  final String message;

  factory SignMessageByIdCommand.fromParams(Map<String, dynamic> params) {
    return SignMessageByIdCommand(
      id: DidInfo.parseDidFromEitherFormat(pick(params, 'id').asStringOrThrow()),
      message: pick(params, 'message').asStringOrThrow(),
    );
  }

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'id': Address.fromPuzzlehash(Puzzlehash(id), didPrefix).address,
      'message': message
    };
  }
}

// Chia Lite Wallet only responds with data field for this command
class SignMessageByIdResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const SignMessageByIdResponse(this.delegate, this.signData);

  @override
  final WalletConnectCommandBaseResponse delegate;
  final SignMessageByIdData signData;

  factory SignMessageByIdResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    return SignMessageByIdResponse(
      baseResponse,
      pick(json, 'data').letJsonOrThrow(SignMessageByIdData.fromJson),
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

class SignMessageByIdData {
  const SignMessageByIdData({
    required this.latestCoinId,
    required this.publicKey,
    required this.signature,
    required this.signingMode,
    required this.success,
  });

  final Bytes latestCoinId;
  final JacobianPoint publicKey;
  final JacobianPoint signature;
  final SigningMode signingMode;
  final bool success;

  factory SignMessageByIdData.fromJson(Map<String, dynamic> json) {
    return SignMessageByIdData(
      latestCoinId: pick(json, 'latestCoinId').asStringOrThrow().hexToBytes(),
      publicKey: JacobianPoint.fromHexG1(pick(json, 'pubkey').asStringOrThrow()),
      signature: JacobianPoint.fromHexG2(pick(json, 'signature').asStringOrThrow()),
      signingMode: SigningMode.fromString(pick(json, 'signingMode').asStringOrThrow()),
      success: pick(json, 'success').asBoolOrThrow(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latestCoinId': latestCoinId.toHex(),
      'pubkey': publicKey.toHex(),
      'signature': signature.toHex(),
      'signingMode': signingMode.fullName,
      'success': success,
    };
  }
}
