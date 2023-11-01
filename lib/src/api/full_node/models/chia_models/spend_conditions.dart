import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SpendConditions {
  SpendConditions({
    required this.coinId,
    required this.puzzlehash,
    required this.createCoinConditions,
  });

  factory SpendConditions.fromJson(Map<String, dynamic> json) {
    print(json);
    final createCoinConditions = List<List<dynamic>>.from(json['create_coin'] as Iterable)
        .map(
          (e) => CreateCoinCondition.fromJsonList(List<dynamic>.from(e)),
        )
        .toList();

    final coinId = Bytes.fromHex(json['coin_name'] as String);
    final puzzlehash = Puzzlehash.fromHex(json['puzzle_hash'] as String);

    return SpendConditions(
      coinId: coinId,
      puzzlehash: puzzlehash,
      createCoinConditions: createCoinConditions,
    );
  }
  final Bytes coinId;
  final Puzzlehash puzzlehash;

  final List<CreateCoinCondition> createCoinConditions;
}
