// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class CreateCoinCondition implements Condition {
  static int conditionCode = 51;
  static String conditionCodeHex = '0x33';
  static String opcode = 'CREATE_COIN';

  Puzzlehash destinationPuzzlehash;
  int amount;
  List<Bytes>? memos;

  CreateCoinCondition(this.destinationPuzzlehash, this.amount, {this.memos});

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

  factory CreateCoinCondition.fromJson(Map<String, dynamic> json) {
    final opcodeFromJson = json['opcode'] as String;
    if (opcodeFromJson != opcode) {
      throw InvalidConditionCastException(CreateCoinCondition);
    }
    final vars = json['vars'] as List<String>;
    final puzzlehash = Puzzlehash.fromHex(vars[0]);
    final amount = bytesToInt(Bytes.fromHex(vars[1]), Endian.big);

    List<Bytes>? memos;
    if (vars.length > 2) {
      memos = Program.fromHex(vars[2]).toList().map((e) => e.atom).toList();
    }
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }

  @override
  Program get program {
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
    if (conditionParts.length < 3 || conditionParts[0].toInt() != conditionCode) {
      return false;
    }
    return true;
  }

  @override
  String toString() =>
      'CreateCoinCondition(code: $conditionCode, destinationPuzzlehash: $destinationPuzzlehash, amount: $amount, memos: $memos)';
}
