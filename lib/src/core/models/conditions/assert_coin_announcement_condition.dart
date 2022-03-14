import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class AssertCoinAnnouncementCondition implements Condition {
  static int conditionCode = 61;

  Puzzlehash announcementId;

  AssertCoinAnnouncementCondition(this.announcementId);

  factory AssertCoinAnnouncementCondition.fromParts(Puzzlehash coinId, Puzzlehash message, {Puzzlehash? morphBytes}) {
    if (morphBytes != null) {
      final prefixedMessage = (morphBytes + message).sha256Hash();
      return AssertCoinAnnouncementCondition((coinId + prefixedMessage).sha256Hash());
    }
    return AssertCoinAnnouncementCondition((coinId + message).sha256Hash());
  }

  factory AssertCoinAnnouncementCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(AssertCoinAnnouncementCondition);
    }
    return AssertCoinAnnouncementCondition(Puzzlehash(programList[1].atom));
  }

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(announcementId.bytes),
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
}
