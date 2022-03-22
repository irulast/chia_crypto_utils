// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:chia_utils/src/api/client.dart';
import 'package:chia_utils/src/api/exceptions/internal_server_error.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_record_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_records_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_spend_response.dart';
import 'package:chia_utils/src/core/models/models.dart';
import 'package:chia_utils/src/core/models/spend_bundle.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';


@immutable
class FullNodeHttpRpc implements FullNode{
  const FullNodeHttpRpc(this.baseURL);

  @override
  final String baseURL;

  Client get client => Client(baseURL);

  @override
  Future<CoinRecordsResponse> getCoinRecordsByPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final body = <String, dynamic>{
      'puzzle_hashes': puzzlehashes.map((ph) => ph.toHex()).toList(),
    };
    if (startHeight != null) {
      body['start_height'] = startHeight;
    }
    if (endHeight != null) {
      body['end_height'] = endHeight;
    }
    body['include_spent_coins'] = includeSpentCoins;

    final responseData = await client.sendRequest(
      Uri.parse('get_coin_records_by_puzzle_hashes'),
      body,
    );
    mapResponseToError(responseData);

    return CoinRecordsResponse.fromJson(jsonDecode(responseData.body) as Map<String, dynamic>);
  }

  @override
  Future<ChiaBaseResponse> pushTransaction(SpendBundle spendBundle) async {
    final responseData = await client.sendRequest(
      Uri.parse('push_tx'),
      {'spend_bundle': spendBundle.toJson()},
    );
    mapResponseToError(responseData);

    return ChiaBaseResponse.fromJson(jsonDecode(responseData.body) as Map<String, dynamic>);
  }

  @override
  Future<CoinRecordResponse> getCoinByName(Puzzlehash coinId) async {
    final responseData = await client.sendRequest(Uri.parse('get_coin_record_by_name'), {
      'name': coinId.toHex(),
    });
    mapResponseToError(responseData);

    return CoinRecordResponse.fromJson(jsonDecode(responseData.body) as Map<String, dynamic>);
  }

  @override
  Future<CoinSpendResponse> getPuzzleAndSolution(Puzzlehash coinId, int height) async {
    final responseData = await client.sendRequest(Uri.parse('get_puzzle_and_solution'), {
      'coin_id': coinId.toHex(),
      'height': height,
    });
    mapResponseToError(responseData);

    return CoinSpendResponse.fromJson(jsonDecode(responseData.body) as Map<String, dynamic>);
  }

  static void mapResponseToError(http.Response response) {
    switch(response.statusCode) {
      case 500:
        throw InternalServeErrorException(message: response.body);
    }
  }

  @override
  String toString() => 'FullNode(${client.baseURL})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullNodeHttpRpc &&
          runtimeType == other.runtimeType &&
          baseURL == other.baseURL;

  @override
  int get hashCode => runtimeType.hashCode ^ baseURL.hashCode;
}
