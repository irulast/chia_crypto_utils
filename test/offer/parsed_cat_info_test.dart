import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/parsed_cat_info.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  const pci = ParsedCatInfo(
    assetId: '6d95dae356e32a71db5ddcb42224754a02524c615c5fc35f568c2af04774e589',
    name: 'Stably USD',
    ticker: 'USDS',
    description:
        "Stably USD (symbol: USDS), a one-to-one U.S. Dollar backed, redeemable stablecoin. U.S. Dollar collateral is held in FDIC-insured trust accounts managed by Prime Trust through Stably’s platform. USDS is Stably's inaugural token in a series of stablecoins developed by Stably.",
  );
  test('should return the desired string form', () {
    expect(
      pci.toString(),
      'ParsedCatInfo(amount: ${pci.amount}, assetId: ${pci.assetId}, '
      'name: ${pci.name}, ticker: ${pci.ticker}, '
      'description: ${pci.description})',
    );
  });

  test('should return the desired json form', () {
    expect(pci.toJson(), <String, dynamic>{
      'type': 'cat',
      'amountMojos': pci.amountMojos,
      'assetId': pci.assetId,
      'name': pci.name,
      'ticker': pci.ticker,
      'description': pci.description,
    });
  });
}
