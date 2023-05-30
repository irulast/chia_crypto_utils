// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class DidExitCondition implements Condition {
  DidExitCondition();

  factory DidExitCondition.fromProgram(Program program) {
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(DidExitCondition);
    }
    return DidExitCondition();
  }

  static int conditionCode = 51;
  static int magicNumber = -113;

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.nil,
      Program.fromInt(magicNumber),
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 3) {
      return false;
    }
    if (conditionParts[0].toInt() != conditionCode || conditionParts[2].toInt() != magicNumber) {
      return false;
    }
    return true;
  }
}
