// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CreateCoinAnnouncementCondition implements Condition {
  CreateCoinAnnouncementCondition(this.message);
  static int conditionCode = 60;

  Bytes message;

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(message),
    ]);
  }

  @override
  String toString() => 'CreateCoinAnnouncementCondition(code: $conditionCode, message: $message)';
}
