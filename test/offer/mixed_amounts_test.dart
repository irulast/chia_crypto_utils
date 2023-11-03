import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form using a CAT1 coin', () {
    final mixedAmounts =
        MixedAmounts(cat: {TestData.validCat1Coin0.assetId: 1000});
    expect(
      mixedAmounts.toString(),
      'MixedAmounts(standard: ${mixedAmounts.standard}, cat: ${mixedAmounts.cat}, nftLauncherIds: {})',
    );
  });

  test('should return the desired string form using a CAT2 coin', () {
    final mixedAmounts =
        MixedAmounts(cat: {TestData.validCatCoin0.assetId: 1000});
    expect(
      mixedAmounts.toString(),
      'MixedAmounts(standard: ${mixedAmounts.standard}, cat: ${mixedAmounts.cat}, nftLauncherIds: {})',
    );
  });
}
