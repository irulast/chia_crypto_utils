// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class AssertPuzzleAnnouncementCondition implements Condition {
  static int conditionCode = 63;

  Bytes announcementHash;

  AssertPuzzleAnnouncementCondition(this.announcementHash);

  factory AssertPuzzleAnnouncementCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(AssertPuzzleAnnouncementCondition);
    }
    return AssertPuzzleAnnouncementCondition(Bytes(programList[1].atom));
  }

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(announcementHash),
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
  String toString() =>
      'AssertPuzzleAnnouncementCondition(code: $conditionCode, announcementHash: $announcementHash)';
}
