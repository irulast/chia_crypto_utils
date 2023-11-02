import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class CreateOfferForIdsCommand implements WalletConnectCommand {
  const CreateOfferForIdsCommand({
    required this.offerMap,
    required this.driverDict,
    this.validateOnly = false,
    this.disableJsonFormatting = true,
  });
  factory CreateOfferForIdsCommand.fromParams(Map<String, dynamic> params) {
    return CreateOfferForIdsCommand(
      offerMap: pick(params, 'offer').letJsonOrThrow(
        (json) => json
            .map((key, value) => MapEntry(key, int.parse(value.toString()))),
      ),
      driverDict: pick(params, 'driverDict').letJsonOrThrow((json) => json),
      validateOnly: pick(params, 'validateOnly').asBoolOrFalse(),
      disableJsonFormatting:
          pick(params, 'disableJSONFormatting').asBoolOrFalse(),
    );
  }

  @override
  WalletConnectCommandType get type =>
      WalletConnectCommandType.createOfferForIds;

  /// Map of walletId to amount. If amount is negative, it is being offered,else it is being requested.
  final Map<String, int> offerMap;
  final Map<String, dynamic> driverDict;
  final bool validateOnly;
  final bool disableJsonFormatting;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'offer': offerMap,
      'driverDict': driverDict,
      'validateOnly': validateOnly,
      'disableJSONFormatting': disableJsonFormatting,
    };
  }
}

class CreateOfferForIdsResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const CreateOfferForIdsResponse(this.delegate, this.createOfferData);
  factory CreateOfferForIdsResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final createdOfferData = CreatedOfferData.fromJson(
      pick(json, 'data').letJsonOrThrow((json) => json),
    );

    return CreateOfferForIdsResponse(baseResponse, createdOfferData);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final CreatedOfferData createOfferData;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': createOfferData.toJson(),
    };
  }
}

class CreatedOfferData {
  const CreatedOfferData({
    required this.offer,
    required this.tradeRecord,
  });
  factory CreatedOfferData.fromJson(Map<String, dynamic> json) {
    return CreatedOfferData(
      offer: Offer.fromBech32(pick(json, 'offer').asStringOrThrow()),
      tradeRecord:
          pick(json, 'tradeRecord').letJsonOrThrow(TradeRecord.fromJson),
    );
  }

  final Offer offer;
  final TradeRecord tradeRecord;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'offer': offer.toBech32(),
      'tradeRecord': tradeRecord.toJson(),
    };
  }
}
