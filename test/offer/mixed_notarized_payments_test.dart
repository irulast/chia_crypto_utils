import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  final notarizedPayments = [TestData.cat1NotarizedPayment];
  final mixedNotarizedPayments = MixedNotarizedPayments(
    {
      GeneralCoinType.standard: {null: notarizedPayments},
      GeneralCoinType.cat: {TestData.standardCoin.puzzlehash: notarizedPayments},
    },
  );

  test('should return the desired string form', () {
    expect(
      mixedNotarizedPayments.toString(),
      'MixedNotarizedPayments(${mixedNotarizedPayments.map})',
    );
  });

  test('debug should execute without error', () {
    expect(mixedNotarizedPayments.debug, returnsNormally);
  });
}
