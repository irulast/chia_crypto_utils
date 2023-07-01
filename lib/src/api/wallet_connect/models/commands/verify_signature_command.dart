import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class VerifySignatureCommand implements WalletConnectCommand {
  const VerifySignatureCommand({
    required this.publicKey,
    required this.message,
    required this.signature,
    this.address,
    this.signingMode,
  });

  factory VerifySignatureCommand.fromParams(Map<String, dynamic> params) {
    return VerifySignatureCommand(
      publicKey: JacobianPoint.fromHexG1(pick(params, 'pubkey').asStringOrThrow()),
      message: pick(params, 'message').asStringOrThrow(),
      signature: JacobianPoint.fromHexG2(pick(params, 'signature').asStringOrThrow()),
      address:
          params['address'] != null ? Address(pick(params, 'address').asStringOrThrow()) : null,
      signingMode: SigningMode.maybeFromString(pick(params, 'signingMode').asStringOrNull()),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.verifySignature;

  final JacobianPoint publicKey;
  final String message;
  final JacobianPoint signature;
  final Address? address;

  // Even though parameter is optional in Chia documentation and code, Lite Wallet will throw error when trying
  // to sign if signing mode not included
  final SigningMode? signingMode;

  @override
  Map<String, dynamic> paramsToJson() {
    final json = <String, dynamic>{
      'pubkey': publicKey.toHex(),
      'message': message,
      'signature': signature.toHex(),
    };

    // Chia Lite Wallet will throw error if these fields are present but values are null
    if (address != null) {
      json['address'] = address!.address;
    }

    if (signingMode != null) {
      json['signingMode'] = signingMode!.fullName;
    }

    return json;
  }
}

class VerifySignatureResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const VerifySignatureResponse(this.delegate, this.verifySignatureData);

  factory VerifySignatureResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    return VerifySignatureResponse(
      baseResponse,
      pick(json, 'data').letJsonOrThrow(VerifySignatureData.fromJson),
    );
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final VerifySignatureData verifySignatureData;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': verifySignatureData.toJson(),
    };
  }
}

class VerifySignatureData {
  const VerifySignatureData({
    required this.isValid,
    required this.success,
  });

  factory VerifySignatureData.fromJson(Map<String, dynamic> json) {
    return VerifySignatureData(
      isValid: pick(json, 'isValid').asBoolOrThrow(),
      success: pick(json, 'success').asBoolOrThrow(),
    );
  }

  final bool isValid;
  final bool success;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isValid': isValid,
      'success': success,
    };
  }
}

enum SigningMode {
  chip0002('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG:CHIP-0002_'),
  blsMessageAugUtf8('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG:utf8input_'),
  blsMessageAugHex('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG:hexinput_');

  const SigningMode(this.fullName);

  factory SigningMode.fromString(String modeString) {
    return SigningMode.values.where((value) => value.fullName == modeString).single;
  }

  final String fullName;

  static SigningMode? maybeFromString(String? modeString) {
    if (modeString == null) {
      return null;
    }
    try {
      return SigningMode.fromString(modeString);
    } catch (e) {
      return null;
    }
  }
}
