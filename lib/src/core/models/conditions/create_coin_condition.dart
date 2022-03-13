import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class CreateCoinCondition implements Condition {
  static int conditionCode = 51;

  Puzzlehash destinationHash;
  int amount;
  Puzzlehash? memos;

  CreateCoinCondition(this.destinationHash, this.amount, {this.memos});

  factory CreateCoinCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(CreateCoinCondition);
    }
    return CreateCoinCondition(
      Puzzlehash(programList[1].atom),
      programList[2].toInt(),
      memos: programList.length > 3 ? Puzzlehash(programList[3].atom) : null
    );
  }

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(destinationHash.bytes),
      Program.fromInt(amount)
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 3) {
      return false;
    }
    if (conditionParts[0].toInt() != conditionCode) {
      return false;
    }
    return true;
  }
}
