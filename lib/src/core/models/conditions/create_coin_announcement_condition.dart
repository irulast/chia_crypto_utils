import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';

class CreateCoinAnnouncementCondition implements Condition {
  static int conditionCode = 60;

  Puzzlehash message;

  CreateCoinAnnouncementCondition(this.message);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(message.bytes),
    ]);
  }
}
