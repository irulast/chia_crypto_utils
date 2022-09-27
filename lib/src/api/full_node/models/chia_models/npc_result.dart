import 'package:chia_crypto_utils/src/api/full_node/models/chia_models/spend_conditions.dart';

class NpcResult {
  final int? cost;
  final List<SpendConditions> spendConditionsList;

  NpcResult(this.cost, this.spendConditionsList);

  factory NpcResult.fromJson(Map<String, dynamic> json) {
    final cost = json['clvm_cost'] as int?;
    final conds = json['conds'] as Map<String, dynamic>;
    final spendConditionsList = List<Map<String, dynamic>>.from(conds['spends'] as Iterable)
        .map(SpendConditions.fromJson)
        .toList();

    return NpcResult(cost, spendConditionsList);
  }
}
