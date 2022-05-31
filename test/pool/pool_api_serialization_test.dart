import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_payload.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_request.dart';
import 'package:test/test.dart';

void main() {
  const chiaPayloadHashHex = '7203f68ac0db24552ef336d27f78620426174b968b349f1f621fa2f2c68460f5';
  var chiaRequestJsonString =
      '{"payload": {"launcher_id": "0x9dcf97a184f32623d11a73124ceb99a5709b083721e878a16d78f596718ba7b2", "authentication_token": 12689, "authentication_public_key": "0x97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb", "payout_instructions": "xch1nh8e0gvy7vnz85g6wvfye6ue54cfkzphy8583gtd0r6evuvt57eqm23khw", "suggested_difficulty": None}, "signature": "0xaeaf6e3498455a9ef25fb9315288f04750a39382eb0727bca5b399deaeb4b8fb627074fe8fee3aae832c60bb6db2635c0ed6888a608699deb5b4aa90dd2052aade6a876380854c59064626fe9eb052c2be2afde5d9180368b409cdf5b619f390"}';
  chiaRequestJsonString = chiaRequestJsonString.replaceAll('None', 'null');
  final chiaRequestJson = jsonDecode(chiaRequestJsonString) as Map<String, dynamic>;

  final launcherId = Program.fromBool(true).hash();
  const authenticationToken = 12689;
  final authenticationPublicKey = JacobianPoint.generateG1();

  final mnemonic =
      'grab anger oval lady obvious minute fork minute addict scan subject glove garbage news million cool board sister program romance appear visit axis moment'
          .split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final testOwnerSecretKey = keychainSecret.masterPrivateKey;

  final payoutInstructions = Address.fromPuzzlehash(launcherId, 'xch');

  print('launcherId: $launcherId');
  print('authenticationToken: $authenticationToken');
  print('authenticationPublicKey: $authenticationPublicKey');
  print('payoutInstructions: $payoutInstructions');

  print('ownerSecretKey: $testOwnerSecretKey');

  final payload = PostFarmerPayload(
    launcherId: launcherId,
    authenticationToken: authenticationToken,
    authenticationPublicKey: authenticationPublicKey,
    payoutInstructions: payoutInstructions,
  );

  test('should correctly serialize post farmer payload', () {
    final payloadSerialized = payload.toBytes().sha256Hash();
    expect(payloadSerialized.toHex(), equals(chiaPayloadHashHex));
  });

  // test('should form post request correctly', () {
  //   final signature = AugSchemeMPL.sign(testOwnerSecretKey, payload.toBytes().sha256Hash());
  //   final request = PostFarmerRequest(payload, signature);

  // });
}
