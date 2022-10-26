import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  // CreateWalletWithPlotNFTCommand used to generate test values
  final launcherId =
      Bytes.fromHex('08f65801d644b71f1388d269c284f48ad5ce0a7b3cc83a3a13f54708f88dea78');
  final targetPuzzlehash =
      Puzzlehash.fromHex('6bde1e0c6f9d3b93dc5e7e878723257ede573deeed59e3b4a90f5c86de1a0bd3');
  const authenticationToken = 5553478;

  final authenticationSecretKey =
      PrivateKey.fromHex('4405803e8ee6473da0d3d316a2bfa12bdf0fb03ab321872fbd258b536613a865');

  final authenticationPayload = AuthenticationPayload(
    endpoint: AuthenticationEndpoint.get_farmer,
    launcherId: launcherId,
    targetPuzzlehash: targetPuzzlehash,
    authenticationToken: authenticationToken,
  );

  final expectedSignature = JacobianPoint.fromHexG2(
    '0xb0596e71687471eb07672a1f7827418d293feb2935ed16f09dc3f4994ecb7aaabb0a3696edceb2e4345ddf3dc41a34d414fc2bb8660aea35d0b4bdfc75eb124e4db5e4d6a0c0bf9becc4eb190b432bf20e2035c86c55f942ac3f15ce698bdbd1',
  );

  test('should correctly serialize authentication payload', () {
    final signature = AugSchemeMPL.sign(
      authenticationSecretKey,
      authenticationPayload.toBytes().sha256Hash(),
    );

    expect(signature, equals(expectedSignature));
  });
}
