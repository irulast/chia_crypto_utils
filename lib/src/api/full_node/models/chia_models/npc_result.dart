import 'package:chia_crypto_utils/src/api/full_node/models/chia_models/npc.dart';

class NpcResult {
  final int? cost;
  final List<Npc> npcList;

  NpcResult(this.cost, this.npcList);

  factory NpcResult.fromJson(Map<String, dynamic> json) {
    final cost = json['clvm_cost'] as int?;
    final npcList =
        List<Map<String, dynamic>>.from(json['npc_list'] as Iterable).map(Npc.fromJson).toList();
    return NpcResult(cost, npcList);
  }
}
