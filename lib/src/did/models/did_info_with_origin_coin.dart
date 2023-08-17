import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:tuple/tuple.dart';

class DidInfoWithOriginCoin with DidInfoDecoratorMixin, ToJsonMixin {
  const DidInfoWithOriginCoin({required this.didInfo, required this.originCoin});

  @override
  final DidInfo didInfo;
  final CoinPrototype originCoin;

  // conforms to Chia's DidInfo JSON format
  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'origin_coin': originCoin.toJson(),
      'backup_ids': didInfo.backupIds?.map((id) => id.toHex()).toList(),
      'num_of_backup_ids_needed': didInfo.backupIds?.length ?? 0,
      'parent_info': [
        Tuple2(didInfo.coin.id.toHex(), didInfo.lineageProof.toJson()).toList(),
      ],
      'current_inner': didInfo.innerPuzzle.toHex(),
      'temp_coin': null,
      'temp_puzhash': null,
      'temp_pubkey': null,
      'sent_recovery_transaction': false,
      'metadata': didInfo.metadata.map.toString(),
    };
  }
}
