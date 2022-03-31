// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';

class Payment {
  int amount;
  Puzzlehash puzzlehash;
  List<Bytes>? memos;

  Payment(this.amount, this.puzzlehash, {List<dynamic>? memos}) {
    if (memos == null) {
      return;
    }
    if (memos is List<String>) {
      this.memos = memos.map((memo) => Bytes(utf8.encode(memo))).toList();
    } else if (memos is List<int>) {
      this.memos = memos.map((memo) => Bytes(utf8.encode(memo.toString()))).toList();
    } else if (memos is List<Bytes>) {
      this.memos = memos;
    } else {
      throw ArgumentError('Unsupported type for memos. Must be Bytes, String, or int');
    }
  }

  CreateCoinCondition toCreateCoinCondition() {
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }
}
