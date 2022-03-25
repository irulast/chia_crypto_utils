import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';

class SimulatorHttpRpc extends FullNodeHttpRpc {
  const SimulatorHttpRpc(String baseUrl, {String? certPath, String? keyPath}) : super(
    baseUrl, certPath: certPath, keyPath: keyPath,
  );

  Future<ChiaBaseResponse> farmTransactionBlock(Address address) async {
    final responseData = await client.sendRequest(
      Uri.parse('farm_tx_block'),
      {'address': address.address},
    );
    FullNodeHttpRpc.mapResponseToError(responseData);

    return ChiaBaseResponse.fromJson(jsonDecode(responseData.body) as Map<String, dynamic>);
  }  
}
