// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';
import 'package:meta/meta.dart';

class AggSigMeCondition implements Condition {
  AggSigMeCondition(this.publicKey, this.message);

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
  static const conditionCode = 50;

  final JacobianPoint publicKey;
  final Bytes message;

  @override
  int get code => conditionCode;

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromAtom(publicKey.toBytes()),
      Program.fromAtom(message),
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

  @override
  String toString() =>
      'AggSigCondition(code: $conditionCode, publicKey: $publicKey, message: $message)';
}

@immutable
class AggSigMeConditionWithFullMessage {
  const AggSigMeConditionWithFullMessage(this.condition, this.fullMessage);

  final AggSigMeCondition condition;
  final Bytes fullMessage;
}
