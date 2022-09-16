// import 'package:chia_crypto_utils/chia_crypto_utils.dart';

// class Npc {
//   Npc({
//     required this.coinId,
//     required this.puzzlehash,
//     required this.createCoinConditions,
//   });

//   factory Npc.fromJson(Map<String, dynamic> json) {
//     final coinId = Bytes.fromHex(json['coin_name'] as String);
//     final puzzlehash = Puzzlehash.fromHex(json['puzzle_hash'] as String);

//     final conditionsMapList = List<Map<String, dynamic>>.from(json['spends'] as List<dynamic>);
//     var createCoinConditions = <CreateCoinCondition>[];
//     for (final conditionsMap in conditionsMapList){

//     } 
//     if (createCoinConditionsTuples.isNotEmpty) {
//       final createCoinConditionsList = createCoinConditionsTuples.first[1] as Iterable;

//       createCoinConditions = List<Map<String, dynamic>>.from(createCoinConditionsList)
//           .map(CreateCoinCondition.fromJson)
//           .toList();
//     }

//     return Npc(coinId: coinId, puzzlehash: puzzlehash, createCoinConditions: createCoinConditions);
//   }

//   final Bytes coinId;
//   final Puzzlehash puzzlehash;

//   final List<CreateCoinCondition> createCoinConditions;
// }
