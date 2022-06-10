// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class Payment {
  final int amount;
  final Puzzlehash puzzlehash;
  final List<Bytes>? memos;

  Payment(this.amount, this.puzzlehash, {List<dynamic>? memos})
      : memos = memos == null
            ? null
            : memos is List<String>
                ? memos.map((memo) => Bytes(utf8.encode(memo))).toList()
                : memos is List<int>
                    ? memos.map((memo) => Bytes(utf8.encode(memo.toString()))).toList()
                    : memos is List<Bytes>
                        ? memos
                        : throw ArgumentError(
                            'Unsupported type for memos. Must be Bytes, String, or int',
                          );

  CreateCoinCondition toCreateCoinCondition() {
    return CreateCoinCondition(puzzlehash, amount, memos: memos);
  }

  Program toProgram() {
    return Program.list([
      Program.fromBytes(puzzlehash),
      Program.fromInt(amount),
      Program.list(
        memos?.map(Program.fromBytes).toList() ?? [],
      ),
    ]);
  }

  factory Payment.fromProgram(Program program) {
    final programList = program.toList();
    return Payment(
      programList[1].toInt(),
      Puzzlehash(programList[0].atom),
      memos:
          programList.length > 2 ? programList[2].toList().map((p) => p.atom).toList() : <Bytes>[],
    );
  }
  @override
  String toString() => 'Payment(amount: $amount, puzzlehash: $puzzlehash, memos: $memos)';

  @override
  bool operator ==(Object other) =>
      other is Payment && puzzlehash == other.puzzlehash && amount == other.amount;

  @override
  int get hashCode => puzzlehash.hashCode ^ amount.hashCode;
}

extension PaymentValue on List<Payment> {
  int get totalValue {
    return fold(0, (int previousValue, payment) => previousValue + payment.amount);
  }
}
