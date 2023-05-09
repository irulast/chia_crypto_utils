// ignore_for_file: lines_longer_than_80_chars

import 'package:test/test.dart';

import '../util/test_data.dart';

Future<void> main() async {
  test('does not error on valid CAT1', () {
    expect(TestData.validCat1Coin0.assetId, TestData.cat1AssetId);
  });

  test('does not error on valid CAT2', () {
    expect(TestData.validCatCoin0.assetId, TestData.catAssetId);
  });
}
