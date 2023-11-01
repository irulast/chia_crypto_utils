import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class TakeOfferCommand implements WalletConnectCommand {
  const TakeOfferCommand({
    required this.offer,
    required this.fee,
  });
  factory TakeOfferCommand.fromParams(Map<String, dynamic> params) {
    return TakeOfferCommand(
      offer: pick(params, 'offer').asStringOrThrow(),
      fee: pick(params, 'fee').asIntOrThrow(),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.takeOffer;

  final String offer;
  final int fee;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'offer': offer,
      'fee': fee,
    };
  }
}

class TakeOfferResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const TakeOfferResponse(
    this.delegate,
    this.takeOfferData,
  );
  factory TakeOfferResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final takeOfferData = pick(json, 'data').letJsonOrThrow(TakeOfferData.fromJson);
    return TakeOfferResponse(baseResponse, takeOfferData);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final TakeOfferData takeOfferData;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...delegate.toJson(),
      'data': takeOfferData.toJson(),
    };
  }
}

class TakeOfferData {
  const TakeOfferData({
    required this.tradeRecord,
    required this.success,
  });
  factory TakeOfferData.fromJson(Map<String, dynamic> json) {
    return TakeOfferData(
      tradeRecord: pick(json, 'tradeRecord').letJsonOrThrow(TradeRecord.fromJson),
      success: pick(json, 'success').asBoolOrThrow(),
    );
  }

  final TradeRecord tradeRecord;
  final bool success;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tradeRecord': tradeRecord.toJson(),
      'success': success,
    };
  }
}

class TradeRecord {
  TradeRecord({
    required this.confirmedAtIndex,
    this.acceptedAtTime,
    required this.createdAtTime,
    required this.isMyOffer,
    required this.sent,
    this.sentTo = const [],
    this.takenOffer,
    required this.coinsOfInterest,
    required this.tradeId,
    required this.status,
    this.summary,
  });

  factory TradeRecord.fromJson(Map<String, dynamic> json) {
    return TradeRecord(
      confirmedAtIndex: pick(json, 'confirmedAtIndex').asIntOrThrow(),
      acceptedAtTime: pick(json, 'acceptedAtTime').asIntOrNull(),
      createdAtTime: pick(json, 'createdAtTime').asIntOrThrow(),
      isMyOffer: pick(json, 'isMyOffer').asBoolOrThrow(),
      sent: pick(json, 'sent').asIntOrThrow(),
      sentTo: pick(json, 'sentTo').asListOrEmpty((p0) => p0.asString()),
      coinsOfInterest: pick(json, 'coinsOfInterest').letJsonListOrThrow(CoinPrototype.fromJson),
      tradeId: pick(json, 'tradeId').asStringOrThrow().hexToBytes(),
      status: TradeStatus.fromString(pick(json, 'status').asStringOrThrow()),
      takenOffer: pick(json, 'takenOffer').asStringOrNull(),
      summary: pick(json, 'summary').asStringOrNull(),
    );
  }
  final int confirmedAtIndex;
  final int? acceptedAtTime;
  final int createdAtTime;
  final bool isMyOffer;
  final int sent;
  final List<String> sentTo;
  final String? takenOffer;
  final List<CoinPrototype> coinsOfInterest;
  final Bytes tradeId;
  final TradeStatus status;
  final String? summary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'confirmedAtIndex': confirmedAtIndex,
      'createdAtTime': createdAtTime,
      'isMyOffer': isMyOffer,
      'sent': sent,
      'sentTo': sentTo,
      'coinsOfInterest': coinsOfInterest.map((coin) => coin.toJson()).toList(),
      'tradeId': tradeId.toHex(),
      'status': status.upperCaseLabel,
      'takenOffer': takenOffer,
      'summary': summary,
    };
  }
}

enum TradeStatus {
  pendingAccept('PENDING_ACCEPT'),
  pendingConfirm('PENDING_CONFIRM'),
  pendingCancel('PENDING_CANCEL'),
  cancelled('CANCELLED'),
  confirmed('CONFIRMED'),
  failed('FAILED');

  const TradeStatus(this.upperCaseLabel);

  factory TradeStatus.fromString(String label) =>
      TradeStatus.values.where((value) => value.upperCaseLabel == label).single;

  final String upperCaseLabel;
}
