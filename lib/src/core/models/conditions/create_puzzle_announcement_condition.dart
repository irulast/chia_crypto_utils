// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class CreatePuzzleAnnouncementCondition implements Condition {
  CreatePuzzleAnnouncementCondition(this.message);

  factory CreatePuzzleAnnouncementCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(CreatePuzzleAnnouncementCondition);
    }
    return CreatePuzzleAnnouncementCondition(Bytes(programList[1].atom));
  }
  static int conditionCode = 62;

  Bytes message;

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(message),
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
  String toString() => 'CreatePuzzleAnnouncementCondition(code: $conditionCode, message: $message)';
}
