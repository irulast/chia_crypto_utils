import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetSyncStatus implements WalletConnectCommand {
  const GetSyncStatus();

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getSyncStatus;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{};
  }
}

class GetSyncStatusResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetSyncStatusResponse(this.delegate, this.syncStatusData);

  factory GetSyncStatusResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final syncStatusData =
        SyncStatusData.fromJson(pick(json, 'data').letJsonOrThrow((json) => json));

    return GetSyncStatusResponse(baseResponse, syncStatusData);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final SyncStatusData syncStatusData;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': syncStatusData.toJson(),
    };
  }
}

class SyncStatusData {
  const SyncStatusData({
    required this.genesisInitialized,
    required this.synced,
    required this.syncing,
  });

  factory SyncStatusData.fromJson(Map<String, dynamic> json) {
    return SyncStatusData(
      genesisInitialized: pick(json, 'genesisInitialized').asBoolOrThrow(),
      synced: pick(json, 'synced').asBoolOrThrow(),
      syncing: pick(json, 'syncing').asBoolOrThrow(),
    );
  }

  final bool genesisInitialized;
  final bool synced;
  final bool syncing;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'genesisInitialized': genesisInitialized,
      'synced': synced,
      'syncing': syncing,
    };
  }
}
