import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/authentication_payload.dart';
import 'package:chia_crypto_utils/src/api/pool/models/get_farmer_response.dart';
import 'package:chia_crypto_utils/src/api/pool/models/pool_info.dart';
import 'package:chia_crypto_utils/src/api/pool/models/post_farmer_payload.dart';

class PoolInterface {
  const PoolInterface(this.poolUrl, {this.certBytes});

  final String poolUrl;
  final Bytes? certBytes;

  Client get client => Client(poolUrl, certBytes: certBytes);

  Future<PoolInfo> getPoolInfo() async {
    final response = await client.get(Uri.parse('pool_info'));
    return PoolInfo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> addFarmer(PostFarmerPayload payload, JacobianPoint signature) async {
    final response = await client.post(Uri.parse('farmer'), <String, dynamic>{
      'payload': payload.toJson(),
      'signature': signature.toHexWithPrefix(),
    });
    print(response.body);
  }

  Future<GetFarmerResponse> getFarmer(Bytes launcherId, int authenticationToken, JacobianPoint signature) async {
    final response = await client.get(
      Uri.parse('farmer'),
      queryParameters: <String, dynamic>{
        'launcher_id': launcherId.hexWithBytesPrefix,
        'authentication_token': authenticationToken.toString(),
        'signature': signature.toHexWithPrefix(),
      },
    );
    return GetFarmerResponse.fromJson(jsonDecode(response.body)as Map<String, dynamic>);
  }
}
