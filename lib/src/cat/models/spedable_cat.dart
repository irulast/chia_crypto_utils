import 'dart:math';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';

class SpendableCat {
  CatCoin coin;
  Program innerPuzzle;
  Program innerSolution;
  int? subtotal;

  SpendableCat({
    required this.coin,
    required this.innerPuzzle,
    required this.innerSolution,
  });

  Program makeStandardCoinProgram() {
    return Program.list([
      Program.fromBytes(coin.parentCoinInfo.bytes),
      Program.fromBytes(innerPuzzle.hash()),
      Program.fromInt(coin.amount),
    ]);
  }

  static void calculateAndAttachSubtotals(List<SpendableCat> spendableCats) {
    final spendInfoMap = <Puzzlehash, SpendableCat>{};
    final deltasMap = <Puzzlehash, int>{};

    // calculate deltas
    for (final spendableCat in spendableCats)  {
      final conditionPrograms = spendableCat.innerPuzzle.run(spendableCat.innerSolution).program.toList();

      var total = 0;
      for (final createCoinConditionProgram in conditionPrograms.where(CreateCoinCondition.isThisCondition)) {
        if (!createCoinConditionProgram.toSource().contains('-113')) {
          final createCoinCondition = CreateCoinCondition.fromProgram(createCoinConditionProgram);
          total += createCoinCondition.amount;
        }
      }
      spendInfoMap[spendableCat.coin.id] = spendableCat;
      deltasMap[spendableCat.coin.id] = spendableCat.coin.amount - total;
    }

    //calculate subtotals
    final subtotalsMap = <Puzzlehash, int>{};
    var subtotal = 0;
    deltasMap.forEach((coinId, delta) { 
      subtotalsMap[coinId] = subtotal;
      subtotal += delta;
    });

    final subtotalOffset = subtotalsMap.values.reduce(min);
    final standardizedSubtotals = subtotalsMap.map((key, value) => MapEntry(key, value - subtotalOffset));

    // attach subtotals to their respective spendableCat
    // ignore: cascade_invocations
    standardizedSubtotals.forEach((coinId, subtotal) { 
      spendInfoMap[coinId]!.subtotal = subtotal;
    });
  }
}
