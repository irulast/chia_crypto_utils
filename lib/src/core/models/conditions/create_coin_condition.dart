import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';

class CreateCoinCondition implements Condition {
  static int conditionCode = 51;

  int amount;
  Puzzlehash destinationHash;

  CreateCoinCondition(this.amount, this.destinationHash);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(destinationHash.bytes),
      Program.fromInt(amount)
    ]);
  }
}
