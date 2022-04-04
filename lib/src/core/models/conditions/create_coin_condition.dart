// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class CreateCoinCondition implements Condition {
  static int conditionCode = 51;

  Puzzlehash destinationHash;
  int amount;
  List<Bytes>? memos;

  CreateCoinCondition(this.destinationHash, this.amount, {this.memos});

  factory CreateCoinCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(CreateCoinCondition);
    }
    return CreateCoinCondition(
      Puzzlehash(programList[1].atom),
      programList[2].toInt(),
      memos: programList.length > 3
          ? programList[3].toList().map((memo) => Bytes(memo.atom)).toList()
          : null,
    );
  }

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(destinationHash.toBytes()),
      Program.fromInt(amount),
      if (memos != null)
        Program.list(
          memos!.map((memo) => Program.fromBytes(memo.toBytes())).toList(),
        )
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts[0].toInt() != conditionCode) {
      return false;
    }
    return true;
  }
}
