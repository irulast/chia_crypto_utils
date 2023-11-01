import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:tuple/tuple.dart';

class ChiaDidInfo with ToJsonMixin {
  ChiaDidInfo({
    required this.originCoin,
    required this.currentInnerPuzzle,
    this.backupIds,
    this.requiredBackupIds,
    this.metadata,
    this.parentInfo,
    this.tempCoin,
    this.tempPuzzlehash,
    this.tempPubkey,
    this.sentRecoveryTransaction,
  });
  factory ChiaDidInfo.fromJson(Map<String, dynamic> json) {
    return ChiaDidInfo(
      originCoin:
          pick(json, 'origin_coin').letJsonOrThrow(CoinPrototype.fromJson),
      backupIds: pick(json, 'backup_ids').letStringListOrNull(Bytes.fromHex),
      requiredBackupIds: pick(json, 'num_of_backup_ids_needed').asIntOrNull(),
      parentInfo: pick(json, 'parent_info').letListOrNull((listItem) {
        final typed = listItem as List<dynamic>;
        return Tuple2(
          Bytes.fromHex(typed[0] as String),
          LineageProof.fromJson(typed[1] as Map<String, dynamic>),
        );
      }),
      currentInnerPuzzle:
          pick(json, 'current_inner').letStringOrThrow(Program.deserializeHex),
      metadata: pick(json, 'metadata').letJsonOrNull(
          (json) => json.map((key, value) => MapEntry(key, value.toString()))),
      tempCoin: pick(json, 'temp_coin').letJsonOrNull(CoinPrototype.fromJson),
      tempPuzzlehash:
          pick(json, 'temp_puzhash').letStringOrNull(Puzzlehash.fromHex),
      tempPubkey:
          pick(json, 'temp_pubkey').letStringOrNull(JacobianPoint.fromHexG1),
      sentRecoveryTransaction:
          pick(json, 'sent_recovery_transaction').asBoolOrNull(),
    );
  }

  final CoinPrototype originCoin;
  final List<Bytes>? backupIds;
  final int? requiredBackupIds;
  final Program currentInnerPuzzle;
  final Map<String, String>? metadata;
  final List<Tuple2<Bytes, LineageProof>>? parentInfo;
  final CoinPrototype? tempCoin;
  final Puzzlehash? tempPuzzlehash;
  final JacobianPoint? tempPubkey;
  final bool? sentRecoveryTransaction;

  Bytes get did => originCoin.id;

// conforms to Chia's DidInfo JSON format
  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'origin_coin': originCoin.toJson(),
      'backup_ids': backupIds?.map((id) => id.toHex()).toList(),
      'num_of_backup_ids_needed': requiredBackupIds,
      'parent_info':
          parentInfo?.map((e) => [e.item1.toHex(), e.item2.toJson()]).toList(),
      'current_inner': currentInnerPuzzle.toHex(),
      'temp_coin': null,
      'temp_puzhash': null,
      'temp_pubkey': null,
      'sent_recovery_transaction': false,
      'metadata': metadata?.map.toString(),
    };
  }
}
