// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class AggSigMeCondition implements Condition {
  static int conditionCode = 50;

  JacobianPoint publicKey;
  Bytes message;

  AggSigMeCondition(this.publicKey, this.message);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(publicKey.toBytes()),
      Program.fromBytes(message),
    ]);
  }

  factory AggSigMeCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(AggSigMeCondition);
    }
    return AggSigMeCondition(
      JacobianPoint.fromBytesG1(programList[1].atom),
      Bytes(programList[2].atom),
    );
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

  @override
  String toString() =>
      'AggSigCondition(code: $conditionCode, publicKey: $publicKey, message: $message)';
}
