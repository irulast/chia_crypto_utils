// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';

class Payment {
  int amount;
  Puzzlehash puzzlehash;
  Bytes? memos;

  Payment(this.amount, this.puzzlehash, {dynamic memos}) {
    if (memos == null) {
      return;
    }
    if (memos is String) {
      this.memos = Bytes(utf8.encode(memos));
    } else if (memos is int) {
      this.memos = Bytes(utf8.encode(memos.toString()));
    } else if (memos is Bytes) {
      this.memos = memos;
    } else {
      throw ArgumentError('Unsupported type for memos. Must be Bytes, String, or int');
    }
  }

  CreateCoinCondition toCreateCoinCondition() {
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }
}
