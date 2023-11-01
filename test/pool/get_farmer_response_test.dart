import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final getFarmerResponse = GetFarmerResponse.fromJson(
    // json of GetFarmerResponse created from CreateWalletWithPlotNFTCommand output
    jsonDecode(
      '{"authentication_public_key":"0x970449be8e08b3a1d5df7d18f5a5fe4225260ed7c00c65700130114d2be09cca60ad79a5e6c7e3c6974f12029277c548", "payout_instructions": "f7b8e2be4865eaedaeac80f0577f41b89fc0b32f9536e458809548192ea9c528", "current_difficulty": 1, "current_points": 9999}',
    ) as Map<String, dynamic>,
  );

  test('should create from json response', () {
    expect(
      getFarmerResponse.authenticationPublicKey,
      JacobianPoint.fromHexG1(
        '0x970449be8e08b3a1d5df7d18f5a5fe4225260ed7c00c65700130114d2be09cca60ad79a5e6c7e3c6974f12029277c548',
      ),
    );
    expect(
      getFarmerResponse.payoutInstructions,
      Puzzlehash.fromHex('f7b8e2be4865eaedaeac80f0577f41b89fc0b32f9536e458809548192ea9c528'),
    );
    expect(getFarmerResponse.currentDifficulty, 1);
    expect(getFarmerResponse.currentPoints, 9999);
  });
}
