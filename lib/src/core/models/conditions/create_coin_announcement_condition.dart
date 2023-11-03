// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CreateCoinAnnouncementCondition implements Condition {
  CreateCoinAnnouncementCondition(this.message);
  static const conditionCode = 60;

  final Bytes message;

  @override
  int get code => conditionCode;

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromAtom(message),
    ]);
  }

  @override
  String toString() =>
      'CreateCoinAnnouncementCondition(code: $conditionCode, message: $message)';
}
