// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SimulatorHttpRpc extends FullNodeHttpRpc {
  const SimulatorHttpRpc(String baseUrl, {Bytes? certBytes, Bytes? keyBytes})
      : super(
          baseUrl,
          certBytes: certBytes,
          keyBytes: keyBytes,
        );

  Future<ChiaBaseResponse> farmTransactionBlock(Address address) async {
    final responseData = await client.post(
      Uri.parse('farm_tx_block'),
      {'address': address.address},
    );
    FullNodeHttpRpc.mapResponseToError(responseData);

    return ChiaBaseResponse.fromJson(
      jsonDecode(responseData.body) as Map<String, dynamic>,
    );
  }
}
