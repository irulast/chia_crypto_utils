import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should get correct hash code', () {
    final didRecoveryInfo = LineageProof(
      parentCoinInfo: TestData.parentCoinSpend.coin.id,
      innerPuzzlehash: TestData.parentCoinSpend.coin.puzzlehash,
      amount: 1000,
    );
    expect(didRecoveryInfo.hashCode, didRecoveryInfo.toProgram().hashCode);
  });
}
