import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class CheckOfferValidityCommand implements WalletConnectCommand {
  const CheckOfferValidityCommand({
    required this.offer,
  });
  factory CheckOfferValidityCommand.fromParams(Map<String, dynamic> params) {
    return CheckOfferValidityCommand(
      offer: Offer.fromBech32(pick(params, 'offer').asStringOrThrow()),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.checkOfferValidity;

  final Offer offer;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'offer': offer.toBech32()};
  }
}

class CheckOfferValidityResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const CheckOfferValidityResponse(this.delegate, this.offerValidityData);
  factory CheckOfferValidityResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final offerValidityData =
        OfferValidityData.fromJson(pick(json, 'data').letJsonOrThrow((json) => json));

    return CheckOfferValidityResponse(baseResponse, offerValidityData);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final OfferValidityData offerValidityData;

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
  factory OfferValidityData.fromJson(Map<String, dynamic> json) {
    return OfferValidityData(
      valid: json['valid'] as bool,
      id: pick(json, 'id').asStringOrThrow().hexToBytes(),
    );
  }

  final bool valid;
  final Bytes id;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'valid': valid,
      'id': id.toHex(),
    };
  }
}
