import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form of a CAT1 spendable CAT', () {
    final spendableCat = SpendableCat(
      coin: TestData.validCat1Coin0,
      innerPuzzle: Program.fromInt(12345678900),
      innerSolution: Program.fromInt(987654321000),
    );
    expect(
      spendableCat.toString(),
      'SpendableCat(coin: ${spendableCat.coin}, '
      'innerPuzzle: ${spendableCat.innerPuzzle}, '
      'innerSolution: ${spendableCat.innerSolution})',
    );
  });

  test('should return the desired string form of a CAT2 spendable CAT', () {
    final spendableCat = SpendableCat(
      coin: TestData.validCatCoin0,
      innerPuzzle: Program.fromInt(12345678900),
      innerSolution: Program.fromInt(987654321000),
    );
    expect(
      spendableCat.toString(),
      'SpendableCat(coin: ${spendableCat.coin}, '
      'innerPuzzle: ${spendableCat.innerPuzzle}, '
      'innerSolution: ${spendableCat.innerSolution})',
    );
  });
}
