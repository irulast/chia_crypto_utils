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
}
