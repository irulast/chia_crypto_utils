import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';

class Payment {
  int amount;
  Puzzlehash puzzlehash;
  Puzzlehash? memos;

  Payment(this.amount, this.puzzlehash, {this.memos});

  CreateCoinCondition toCreateCoinCondition() {
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }
}
