// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/simulator/responses/auto_farm_response.dart';

class SimulatorHttpRpc extends FullNodeHttpRpc {
  const SimulatorHttpRpc(super.baseUrl, {super.certBytes, super.keyBytes,super.timeout,});

  Future<ChiaBaseResponse> farmTransactionBlocks(
    Address address, {
    int blocks = 1,
    bool transactionBlock = true,
  }) async {
    final responseData = await client.post(
      Uri.parse('farm_block'),
      {'address': address.address, 'blocks': blocks, 'guarantee_tx_block': transactionBlock},
    );
    FullNodeHttpRpc.mapResponseToError(responseData);

    return ChiaBaseResponse.fromJson(
      jsonDecode(responseData.body) as Map<String, dynamic>,
    );
  }

  Future<AutofarmResponse> updateAutofarmConfig({required bool shouldAutofarm}) async {
    final responseData = await client.post(
      Uri.parse('set_auto_farming'),
      {'auto_farm': shouldAutofarm},
    );
    FullNodeHttpRpc.mapResponseToError(responseData);

    return AutofarmResponse.fromJson(
      jsonDecode(responseData.body) as Map<String, dynamic>,
    );
  }

  Future<AutofarmResponse> getAutofarmConfig() async {
    final responseData = await client.post(
      Uri.parse('get_auto_farming'),
      {},
    );
    FullNodeHttpRpc.mapResponseToError(responseData);

    return AutofarmResponse.fromJson(
      jsonDecode(responseData.body) as Map<String, dynamic>,
    );
  }
}
