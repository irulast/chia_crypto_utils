import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form of a CAT1 coin', () {
    expect(
      TestData.validCat1Coin0.toString(),
      'CatCoin('
      'id: ${TestData.validCat1Coin0.id}, '
      'parentCoinInfo: ${TestData.validCat1Coin0.parentCoinInfo}, '
      'puzzlehash: ${TestData.validCat1Coin0.puzzlehash}, '
      'amount: ${TestData.validCat1Coin0.amount}, '
      'assetId: ${TestData.validCat1Coin0.assetId})',
    );
  });

  test('should return the desired string form of a CAT2 coin', () {
    expect(
      TestData.validCatCoin0.toString(),
      'CatCoin('
      'id: ${TestData.validCatCoin0.id}, '
      'parentCoinInfo: ${TestData.validCatCoin0.parentCoinInfo}, '
      'puzzlehash: ${TestData.validCatCoin0.puzzlehash}, '
      'amount: ${TestData.validCatCoin0.amount}, '
      'assetId: ${TestData.validCatCoin0.assetId})',
    );
  });
}
