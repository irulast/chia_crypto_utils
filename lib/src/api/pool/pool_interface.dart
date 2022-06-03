import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/authentication_payload.dart';
import 'package:chia_crypto_utils/src/api/pool/models/get_farmer_response.dart';
import 'package:chia_crypto_utils/src/api/pool/models/pool_info.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_payload.dart';
import 'package:chia_crypto_utils/src/api/pool/pool_http_rest.dart';

class PoolInterface {
  PoolInterface(this.pool);
  final PoolHttpREST pool;

  String get poolUrl => pool.poolUrl;

  Future<PoolInfo> getPoolInfo() async {
    return pool.getPoolInfo();
  }

  Future<void> addFarmer({
    required Bytes launcherId,
    required int authenticationToken,
    required JacobianPoint authenticationPublicKey,
    required Puzzlehash payoutPuzzlehash,
    required PrivateKey singletonOwnerPrivateKey,
    int? suggestedDifficulty,
  }) async {
    final payload = PostFarmerPayload(
      launcherId: launcherId,
      authenticationToken: authenticationToken,
      authenticationPublicKey: authenticationPublicKey,
      payoutPuzzlehash: payoutPuzzlehash,
      suggestedDifficulty: suggestedDifficulty,
    );

    final signature = AugSchemeMPL.sign(
      singletonOwnerPrivateKey,
      payload.toBytes().sha256Hash(),
    );

    await pool.addFarmer(payload, signature);
  }

  Future<Farmer> getFarmer({
    required Bytes launcherId,
    required Puzzlehash targetPuzzlehash,
    required int authenticationToken,
    required PrivateKey authenticationSecretKey,
  }) async {
    final authenticationPayload = AuthenticationPayload(
      endpoint: AuthenticationEndpoint.getFarmer,
      launcherId: launcherId,
      targetPuzzlehash: targetPuzzlehash,
      authenticationToken: authenticationToken,
    );

    final signature = AugSchemeMPL.sign(
      authenticationSecretKey,
      authenticationPayload.toBytes().sha256Hash(),
    );

    return pool.getFarmer(launcherId, authenticationToken, signature);
  }
}
