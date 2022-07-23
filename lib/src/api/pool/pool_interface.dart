import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PoolInterface {
  const PoolInterface(this.pool);
  factory PoolInterface.fromURL(String poolUrl, {String? certificateBytesPath}) {
    return PoolInterface(
      PoolHttpREST(
        poolUrl,
        certBytes: (certificateBytesPath != null)
            ? Bytes(File(certificateBytesPath).readAsBytesSync())
            : null,
      ),
    );
  }

  PoolInterface.fromContext() : pool = PoolHttpREST.fromContext();

  final PoolHttpREST pool;

  String get poolUrl => pool.poolUrl;

  Future<PoolInfo> getPoolInfo() async {
    return pool.getPoolInfo();
  }

  Future<AddFarmerResponse> addFarmer({
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

    return pool.addFarmer(payload, signature);
  }

  Future<GetFarmerResponse> getFarmer({
    required Bytes launcherId,
    required Puzzlehash targetPuzzlehash,
    required int authenticationToken,
    required PrivateKey authenticationSecretKey,
  }) async {
    final authenticationPayload = AuthenticationPayload(
      endpoint: AuthenticationEndpoint.get_farmer,
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
