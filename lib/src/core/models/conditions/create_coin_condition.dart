// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class CreateCoinCondition implements Condition {
  CreateCoinCondition(this.destinationPuzzlehash, this.amount, {this.memos});

  factory CreateCoinCondition.fromJsonList(List<dynamic> vars) {
    final puzzlehash = Puzzlehash.fromHex(vars[0] as String);
    final amount = vars[1] as int;

    // memo only given in list format if its a hint
    Bytes? hint;
    if (vars.length > 2 && vars[2] != Bytes.bytesPrefix) {
      hint = Bytes.fromHex(vars[2] as String);
    }

    final memos = hint != null ? [hint] : null;
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }

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
  static int conditionCode = 51;
  static String conditionCodeHex = '0x33';
  static String opcode = 'CREATE_COIN';

  Puzzlehash destinationPuzzlehash;
  int amount;
  List<Bytes>? memos;

  Payment toPayment() => Payment(amount, destinationPuzzlehash, memos: memos);

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(destinationPuzzlehash),
      Program.fromInt(amount),
      if (memos != null)
        Program.list(
          memos!.map(Program.fromBytes).toList(),
        )
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length < 3 ||
        conditionParts[0].toInt() != conditionCode ||
        conditionParts[2].toInt() == -113) {
      return false;
    }
    return true;
  }

  @override
  String toString() =>
      'CreateCoinCondition(code: $conditionCode, destinationPuzzlehash: $destinationPuzzlehash, amount: $amount, memos: $memos)';
}
