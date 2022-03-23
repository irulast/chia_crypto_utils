import 'dart:convert';
import 'dart:io';

import 'package:chia_utils/src/api/full_node_http_rpc.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/core/models/address.dart';

class SimulatorHttpRpc extends FullNodeHttpRpc {
  const SimulatorHttpRpc(String baseUrl) : super(baseUrl);

  Future<ChiaBaseResponse> farmTransactionBlock(Address address) async {
    final responseData = await client.sendRequest(
      Uri.parse('farm_tx_block'),
      {'address': address.address},
    );
    FullNodeHttpRpc.mapResponseToError(responseData);

    return ChiaBaseResponse.fromJson(jsonDecode(responseData.body) as Map<String, dynamic>);
  }

  Future<void> moveToNextBlock() async {
    await farmTransactionBlock(Address('xch16wztykx2dasqk4lnpz0m2e6rwxf697fy6awhy46waf2dd6qajl7sslnadz'));
  }

  static void deleteDatabase() {
    Directory('/Users/nvjoshi/.chia/mainnet/sim_db')
      .delete(recursive: true);
  }
}
