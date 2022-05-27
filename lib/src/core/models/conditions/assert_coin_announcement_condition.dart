// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class AssertCoinAnnouncementCondition implements Condition {
  static int conditionCode = 61;

  Bytes coinId;
  Bytes message;
  Bytes? morphBytes;

  Bytes get announcementId {
    if (morphBytes != null) {
      final prefixedMessage = (morphBytes! + message).sha256Hash();
      return (coinId + prefixedMessage).sha256Hash();
    }
    return (coinId + message).sha256Hash();
  }

  AssertCoinAnnouncementCondition(this.coinId, this.message, {this.morphBytes});

  static Bytes getAnnouncementIdFromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(AssertCoinAnnouncementCondition);
    }
    return Bytes(programList[1].atom);
  }

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(announcementId),
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
      'AssertCoinAnnouncementCondition(code: $conditionCode, coinId: $coinId, message: $message, morphBytes: $morphBytes)';
}
