import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

/// Base response that contains all additional information that may be included in a response from
/// an executed command other than the data field. Data field varies by command.
abstract class WalletConnectCommandBaseResponse with ToJsonMixin {
  WalletConnectCommandBaseResponse({
    this.status,
    this.endpointName,
    this.requestId,
    this.originalArgs,
    this.startedTimeStamp,
    this.fulfilledTimeStamp,
    this.isUninitialized,
    this.isLoading,
    this.isSuccess,
    this.isError,
  });

  final String? status;
  final WalletConnectCommandType? endpointName;
  final String? requestId;
  final Map<String, dynamic>? originalArgs;
  final int? startedTimeStamp;
  final int? fulfilledTimeStamp;
  final bool? isUninitialized;
  final bool? isLoading;
  final bool? isSuccess;
  final bool? isError;
}

class WalletConnectCommandBaseResponseImp
    with ToJsonMixin
    implements WalletConnectCommandBaseResponse {
  WalletConnectCommandBaseResponseImp({
    this.status,
    this.endpointName,
    this.requestId,
    this.originalArgs,
    this.startedTimeStamp,
    this.fulfilledTimeStamp,
    this.isUninitialized,
    this.isLoading,
    this.isSuccess,
    this.isError,
  });

  @override
  final String? status;
  @override
  final WalletConnectCommandType? endpointName;
  @override
  final String? requestId;
  @override
  final Map<String, dynamic>? originalArgs;
  @override
  final int? startedTimeStamp;
  @override
  final int? fulfilledTimeStamp;
  @override
  final bool? isUninitialized;
  @override
  final bool? isLoading;
  @override
  final bool? isSuccess;
  @override
  final bool? isError;

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // only adding fields if not null to avoid cluttering the JSON response, which for some wallets
    // might only include the data field
    if (status != null) {
      json['status'] = status;
    }

    if (endpointName != null) {
      json['endpointName'] = endpointName?.name;
    }

    if (requestId != null) {
      json['requestId'] = requestId;
    }

    if (originalArgs != null) {
      json['originalArgs'] = originalArgs;
    }

    if (startedTimeStamp != null) {
      json['startedTimeStamp'] = startedTimeStamp;
    }

    if (fulfilledTimeStamp != null) {
      json['fulfilledTimeStamp'] = fulfilledTimeStamp;
    }

    if (isUninitialized != null) {
      json['isUninitialized'] = isUninitialized;
    }

    if (originalArgs != null) {
      json['originalArgs'] = originalArgs;
    }

    if (isLoading != null) {
      json['isLoading'] = isLoading;
    }

    if (isSuccess != null) {
      json['isSuccess'] = isSuccess;
    }

    if (isError != null) {
      json['isError'] = isError;
    }

    return json;
  }

  factory WalletConnectCommandBaseResponseImp.fromJson(Map<String, dynamic> json) {
    return WalletConnectCommandBaseResponseImp(
      status: pick(json, 'status').asStringOrNull(),
      endpointName: pick(json, 'endpointName').letStringOrNull(WalletConnectCommandType.fromString),
      requestId: pick(json, 'requestId').asStringOrNull(),
      originalArgs: pick(json, 'originalArgs').letJsonOrNull((json) => json),
      startedTimeStamp: pick(json, 'startedTimeStamp').asIntOrNull(),
      fulfilledTimeStamp: pick(json, 'fulfilledTimeStamp').asIntOrNull(),
      isUninitialized: pick(json, 'isUninitialized').asBoolOrNull(),
      isLoading: pick(json, 'isLoading').asBoolOrNull(),
      isSuccess: pick(json, 'isSuccess').asBoolOrNull(),
      isError: pick(json, 'isError').asBoolOrNull(),
    );
  }

  factory WalletConnectCommandBaseResponseImp.success({
    required WalletConnectCommand command,
    required int startedTimeStamp,
    String? requestId,
  }) {
    return WalletConnectCommandBaseResponseImp(
      status: 'fulfilled',
      endpointName: command.type,
      requestId: requestId,
      originalArgs: command.paramsToJson(),
      startedTimeStamp: startedTimeStamp,
      fulfilledTimeStamp: DateTime.now().unixTimeStamp,
      isUninitialized: false,
      isLoading: false,
      isSuccess: true,
      isError: false,
    );
  }

  WalletConnectCommandBaseResponseImp.error({
    required this.endpointName,
    this.requestId,
    required this.originalArgs,
    required this.startedTimeStamp,
  })  : status = 'error',
        fulfilledTimeStamp = null,
        isUninitialized = false,
        isLoading = false,
        isSuccess = false,
        isError = true;
}

mixin WalletConnectCommandResponseDecoratorMixin implements WalletConnectCommandBaseResponse {
  WalletConnectCommandBaseResponse get delegate;

  @override
  WalletConnectCommandType? get endpointName => delegate.endpointName;

  @override
  int? get fulfilledTimeStamp => delegate.fulfilledTimeStamp;

  @override
  bool? get isError => delegate.isError;

  @override
  bool? get isLoading => delegate.isLoading;

  @override
  bool? get isSuccess => delegate.isSuccess;

  @override
  bool? get isUninitialized => delegate.isUninitialized;

  @override
  Map<String, dynamic>? get originalArgs => delegate.originalArgs;

  @override
  String? get requestId => delegate.requestId;

  @override
  int? get startedTimeStamp => delegate.startedTimeStamp;

  @override
  String? get status => delegate.status;
}
