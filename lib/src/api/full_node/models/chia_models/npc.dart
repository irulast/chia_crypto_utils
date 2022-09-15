import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Npc {
  Npc({
    required this.coinId,
    required this.puzzlehash,
    required this.createCoinConditions,
  });

  factory Npc.fromJson(Map<String, dynamic> json) {
    final coinId = Bytes.fromHex(json['coin_name'] as String);
    final puzzlehash = Puzzlehash.fromHex(json['puzzle_hash'] as String);

    final conditionsTuples = List<List>.from(json['conditions'] as List<dynamic>);
    final createCoinConditionsTuples = conditionsTuples
        .where((conditionsTuple) => conditionsTuple[0] == CreateCoinCondition.conditionCodeHex)
        .toList();
    var createCoinConditions = <CreateCoinCondition>[];
    if (createCoinConditionsTuples.isNotEmpty) {
      final createCoinConditionsList = createCoinConditionsTuples.first[1] as Iterable;

      createCoinConditions = List<Map<String, dynamic>>.from(createCoinConditionsList)
          .map(CreateCoinCondition.fromJson)
          .toList();
    }

    return Npc(coinId: coinId, puzzlehash: puzzlehash, createCoinConditions: createCoinConditions);
  }

  final Bytes coinId;
  final Puzzlehash puzzlehash;

  final List<CreateCoinCondition> createCoinConditions;
}
