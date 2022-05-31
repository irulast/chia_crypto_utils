import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/pool_info.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_payload.dart';

class PoolInterface {
  const PoolInterface(this.poolUrl);

  final String poolUrl;

  // might need to add mozilla certificate
  Client get client => Client(poolUrl);

  Future<PoolInfo> getPoolInfo() async {
    final response = await client.get(Uri.parse('pool_info'));
    return PoolInfo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> updatePoolFarmer(PostFarmerPayload payload, JacobianPoint signature) async {
    final response = await client.post(Uri.parse('farmer'), <String, dynamic>{
      'payload': payload.toJson(),
      'signature': signature.toHexWithPrefix(),
    });
    print(response.body);
  }
}
