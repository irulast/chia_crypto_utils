import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final testPayment = Payment(100, Program.fromInt(1).hash());
  final comparisonPayments = [
    Payment(100, Program.fromInt(1).hash()),
    Payment(100, Program.fromInt(2).hash()),
    Payment(200, Program.fromInt(1).hash()),
  ];

  test('payments should correctly assess equality', () {
    expect(testPayment == comparisonPayments[0], true);
    expect(testPayment != comparisonPayments[1], true);
    expect(testPayment != comparisonPayments[2], true);
  });

  test('payments should form set correctly', () {
    final paymentSet = Set<Payment>.from(comparisonPayments.sublist(1));
    expect(paymentSet.contains(testPayment), false);

    paymentSet.add(comparisonPayments[0]);
    expect(paymentSet.contains(testPayment), true);
  });

  test('should correctly extract payment memo strings', () {
    const memoStrings = ['yo', 'sup'];
    final memos = memoStrings.map((e) => Memo(utf8.encode(e))).toList();

    final payment = Payment(100, Program.fromInt(1).hash(), memos: memos);
    expect(payment.memoStrings[0], equals(memoStrings[0]));
    expect(payment.memoStrings[1], equals(memoStrings[1]));
  });
}
