import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PoolHttpREST {
  const PoolHttpREST(this.poolUrl, {this.certBytes});

  final String poolUrl;
  final Bytes? certBytes;

  Client get client => Client(poolUrl, certBytes: certBytes);

  Future<PoolInfo> getPoolInfo() async {
    final response = await client.get(Uri.parse('pool_info'));
    mapResponseToError(response);

    return PoolInfo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> addFarmer(PostFarmerPayload payload, JacobianPoint signature) async {
    final response = await client.post(Uri.parse('farmer'), <String, dynamic>{
      'payload': payload.toJson(),
      'signature': signature.toHexWithPrefix(),
    });
    mapResponseToError(response);
  }

  Future<GetFarmerResponse> getFarmer(
    Bytes launcherId,
    int authenticationToken,
    JacobianPoint signature,
  ) async {
    final response = await client.get(
      Uri.parse('farmer'),
      queryParameters: <String, dynamic>{
        'launcher_id': launcherId.hexWithBytesPrefix,
        'authentication_token': authenticationToken.toString(),
        'signature': signature.toHexWithPrefix(),
      },
    );
    mapResponseToError(response);
    return GetFarmerResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void mapResponseToError(Response response) {
    switch (response.statusCode) {
      case 500:
        throw InternalServeErrorException(message: response.body);
    }

    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
    if (!PoolErrorResponse.isErrorResponse(bodyJson)) {
      return;
    }

    final poolErrorResponse = PoolErrorResponse.fromJson(bodyJson);
    throw PoolResponseException(poolErrorResponse, poolUrl);
  }
}
