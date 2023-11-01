import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form', () {
    final mixedPayments = MixedPayments({
      GeneralCoinType.standard: {
        null: [Payment(1000, TestData.standardCoin.puzzlehash)],
      },
    });
    expect(
      mixedPayments.toString(),
      'MixedPayments(${mixedPayments.map})',
    );
  });
}
