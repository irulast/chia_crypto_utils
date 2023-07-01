import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class CheckOfferValidityCommand implements WalletConnectCommand {
  const CheckOfferValidityCommand({
    required this.offerData,
  });

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.checkOfferValidity;

  final String offerData;

  factory CheckOfferValidityCommand.fromParams(Map<String, dynamic> params) {
    return CheckOfferValidityCommand(
      offerData: pick(params, 'offerData').asStringOrThrow(),
    );
  }

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'offerData': offerData};
  }
}

class CheckOfferValidityResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const CheckOfferValidityResponse(this.delegate, this.offerValidityData);

  @override
  final WalletConnectCommandBaseResponse delegate;
  final OfferValidityData offerValidityData;

  factory CheckOfferValidityResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final offerValidityData =
        OfferValidityData.fromJson(pick(json, 'data').letJsonOrThrow((json) => json));

    return CheckOfferValidityResponse(baseResponse, offerValidityData);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': offerValidityData.toJson(),
    };
  }
}

class OfferValidityData {
  const OfferValidityData({
    required this.valid,
    required this.id,
  });

  final bool valid;
  final Bytes id;

  factory OfferValidityData.fromJson(Map<String, dynamic> json) {
    return OfferValidityData(
      valid: json['valid'] as bool,
      id: pick(json, 'id').asStringOrThrow().hexToBytes(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'valid': valid,
      'id': id.toHex(),
    };
  }
}
