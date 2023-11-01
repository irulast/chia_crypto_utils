import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  const chiaPayloadHashHex = '12cce226f66188ea5c93d8337f0fa7512cec31c383e5ca897dcba04f60e5cec0';

  final launcherId = Program.fromBool(true).hash();
  const authenticationToken = 12689;
  final authenticationPublicKey = JacobianPoint.generateG1();

  final payoutInstructions = Puzzlehash(launcherId);

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

  test('should correctly convert post farmer payload to json', () {
    expect(payload.toJson(), <String, dynamic>{
      'launcher_id': payload.launcherId.toHexWithPrefix(),
      'authentication_token': payload.authenticationToken,
      'authentication_public_key': payload.authenticationPublicKey.toHexWithPrefix(),
      'payout_instructions': payload.payoutPuzzlehash.toHexWithPrefix(),
      'suggested_difficulty': payload.suggestedDifficulty,
    });
  });

  test('should correctly convert post farmer request to json', () {
    final signature = JacobianPoint.generateG2();
    final request = PostFarmerRequest(payload, signature);

    expect(request.toJson(), <String, dynamic>{
      'payload': payload.toJson(),
      'signature': signature.toHexWithPrefix(),
    });
  });
}
