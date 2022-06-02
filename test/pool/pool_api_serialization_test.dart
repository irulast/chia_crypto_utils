import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_payload.dart';
import 'package:test/test.dart';

void main() {
  const chiaPayloadHashHex = '7203f68ac0db24552ef336d27f78620426174b968b349f1f621fa2f2c68460f5';

  final launcherId = Program.fromBool(true).hash();
  const authenticationToken = 12689;
  final authenticationPublicKey = JacobianPoint.generateG1();

  final mnemonic =
      'grab anger oval lady obvious minute fork minute addict scan subject glove garbage news million cool board sister program romance appear visit axis moment'
          .split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final testOwnerSecretKey = keychainSecret.masterPrivateKey;

  final payoutInstructions = Puzzlehash(launcherId);

  print('launcherId: $launcherId');
  print('authenticationToken: $authenticationToken');
  print('authenticationPublicKey: $authenticationPublicKey');
  print('payoutInstructions: $payoutInstructions');

  print('ownerSecretKey: $testOwnerSecretKey');

  final payload = PostFarmerPayload(
    launcherId: launcherId,
    authenticationToken: authenticationToken,
    authenticationPublicKey: authenticationPublicKey,
    payoutPuzzlehash: payoutInstructions,
  );

  test('should correctly serialize post farmer payload', () {
    final payloadSerialized = payload.toBytes().sha256Hash();
    expect(payloadSerialized.toHex(), equals(chiaPayloadHashHex));
  });
}
