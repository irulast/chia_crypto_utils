import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form using a CAT1 coin', () {
    final mixedCoins = MixedCoins(cats: [TestData.validCat1Coin0]);
    expect(
      mixedCoins.toString(),
      'MixedCoins(standard: ${mixedCoins.standardCoins}, cat: ${mixedCoins.catMap}, nft: ${mixedCoins.nfts})',
    );
  });

  test('should return the desired string form using a CAT2 coin', () {
    final mixedCoins = MixedCoins(cats: [TestData.validCatCoin0]);
    expect(
      mixedCoins.toString(),
      'MixedCoins(standard: ${mixedCoins.standardCoins}, cat: ${mixedCoins.catMap}, nft: ${mixedCoins.nfts})',
    );
  });
}
