// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../../../util/test_data.dart';

void main() {
  test('should correctly serialize and deserialize a CAT1 CatCoin', () {
    final catCoinSerialized = TestData.validCat1Coin0.toCatBytes();
    final catCoinDeserialized = CatCoin.fromBytes(catCoinSerialized);
    expect(catCoinDeserialized.toCatBytes(), equals(catCoinSerialized));
  });

  test('should correctly serialize and deserialize a CAT2 CatCoin', () {
    final catCoinSerialized = TestData.validCatCoin0.toCatBytes();
    final catCoinDeserialized = CatCoin.fromBytes(catCoinSerialized);
    expect(catCoinDeserialized.toCatBytes(), equals(catCoinSerialized));
  });
}
