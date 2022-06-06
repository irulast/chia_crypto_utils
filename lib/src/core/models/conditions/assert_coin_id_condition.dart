// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class AssertMyCoinIdCondition implements Condition {
  static int conditionCode = 70;

  Bytes coinId;

  AssertMyCoinIdCondition(this.coinId);

  factory AssertMyCoinIdCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(AssertMyCoinIdCondition);
    }
    return AssertMyCoinIdCondition(Bytes(programList[1].atom));
  }

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(coinId),
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 2) {
      return false;
    }
    if (conditionParts[0].toInt() != conditionCode) {
      return false;
    }
    return true;
  }

  @override
  String toString() => 'AssertMyCoinIdCondition(code: $conditionCode, coinId: $coinId)';
}
