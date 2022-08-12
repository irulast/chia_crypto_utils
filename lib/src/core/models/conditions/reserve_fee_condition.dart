// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class ReserveFeeCondition implements Condition {
  static int conditionCode = 52;

  int feeAmount;

  ReserveFeeCondition(this.feeAmount);

  factory ReserveFeeCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(ReserveFeeCondition);
    }
    return ReserveFeeCondition(programList[1].toInt());
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 2) {
      return false;
    }
    return conditionParts[0].toInt() == conditionCode;
  }

  @override
  Program get program {
    return Program.list(
      [Program.fromInt(conditionCode), Program.fromInt(feeAmount)],
    );
  }

  @override
  String toString() => 'ReserveFeeCondition(code: $conditionCode, feeAmount: $feeAmount)';
}
