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
    this.startedTimestamp,
    this.fulfilledTimestamp,
    this.isUninitialized,
    this.isLoading,
    this.isSuccess,
    this.isError,
  });

  final String? status;
  final WalletConnectCommandType? endpointName;
  final String? requestId;
  final Map<String, dynamic>? originalArgs;
  final int? startedTimestamp;
  final int? fulfilledTimestamp;
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
    this.startedTimestamp,
    this.fulfilledTimestamp,
    this.isUninitialized,
    this.isLoading,
    this.isSuccess,
    this.isError,
  });
  factory WalletConnectCommandBaseResponseImp.fromJson(
      Map<String, dynamic> json) {
    return WalletConnectCommandBaseResponseImp(
      status: pick(json, 'status').asStringOrNull(),
      endpointName: pick(json, 'endpointName')
          .letStringOrNull(WalletConnectCommandType.fromString),
      requestId: pick(json, 'requestId').asStringOrNull(),
      originalArgs: pick(json, 'originalArgs').letJsonOrNull((json) => json),
      startedTimestamp: pick(json, 'startedTimestamp').asIntOrNull(),
      fulfilledTimestamp: pick(json, 'fulfilledTimestamp').asIntOrNull(),
      isUninitialized: pick(json, 'isUninitialized').asBoolOrNull(),
      isLoading: pick(json, 'isLoading').asBoolOrNull(),
      isSuccess: pick(json, 'isSuccess').asBoolOrNull(),
      isError: pick(json, 'isError').asBoolOrNull(),
    );
  }

  factory WalletConnectCommandBaseResponseImp.success({
    required WalletConnectCommand command,
    required int startedTimestamp,
    String? requestId,
  }) {
    return WalletConnectCommandBaseResponseImp(
      status: 'fulfilled',
      endpointName: command.type,
      requestId: requestId,
      originalArgs: command.paramsToJson(),
      startedTimestamp: startedTimestamp,
      fulfilledTimestamp: DateTime.now().unixTimestamp,
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
    required this.startedTimestamp,
  })  : status = 'error',
        fulfilledTimestamp = null,
        isUninitialized = false,
        isLoading = false,
        isSuccess = false,
        isError = true;

  @override
  final String? status;
  @override
  final WalletConnectCommandType? endpointName;
  @override
  final String? requestId;
  @override
  final Map<String, dynamic>? originalArgs;
  @override
  final int? startedTimestamp;
  @override
  final int? fulfilledTimestamp;
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

    // only add fields if not null to avoid cluttering the JSON response, which for some commands
    // executed by certain wallets might only include the data field
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

    if (startedTimestamp != null) {
      json['startedTimestamp'] = startedTimestamp;
    }

    if (fulfilledTimestamp != null) {
      json['fulfilledTimestamp'] = fulfilledTimestamp;
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
}

mixin WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  WalletConnectCommandBaseResponse get delegate;

  @override
  WalletConnectCommandType? get endpointName => delegate.endpointName;

  @override
  int? get fulfilledTimestamp => delegate.fulfilledTimestamp;

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
  int? get startedTimestamp => delegate.startedTimestamp;

  @override
  String? get status => delegate.status;
}
