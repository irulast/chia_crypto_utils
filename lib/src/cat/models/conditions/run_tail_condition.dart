// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class RunTailCondition implements Condition {
  static int conditionCode = 51;
  static int magicCatNumber = -113;

  Program tail;
  Program tailSolution;

  RunTailCondition(this.tail, this.tailSolution);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromInt(0),
      Program.fromInt(magicCatNumber),
      tail,
      tailSolution
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 5) {
      return false;
    }
    if (conditionParts[0].toInt() != conditionCode || conditionParts[2].toInt() != magicCatNumber) {
      return false;
    }
    return true;
  }

  @override
  String toString() =>
      'RunTailCondition(code: $conditionCode, tail: $tail, tailSolution: $tailSolution)';
}
