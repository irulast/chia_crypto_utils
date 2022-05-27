// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CreateCoinAnnouncementCondition implements Condition {
  static int conditionCode = 60;

  Bytes message;

  CreateCoinAnnouncementCondition(this.message);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(message),
    ]);
  }

  @override
  String toString() => 'CreateCoinAnnouncementCondition(code: $conditionCode, message: $message)';
}
