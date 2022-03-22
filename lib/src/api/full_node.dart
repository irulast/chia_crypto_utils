// ignore_for_file: avoid_dynamic_calls, lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_utils/src/api/client.dart';
import 'package:chia_utils/src/core/models/bytes.dart';
import 'package:chia_utils/src/core/models/coin.dart';
import 'package:chia_utils/src/core/models/coin_spend.dart';
import 'package:chia_utils/src/core/models/spend_bundle.dart';
import 'package:meta/meta.dart';

@immutable
class FullNode {
  const FullNode(this.baseURL);

  final String baseURL;

  Client get client => Client(baseURL);

  Future<List<Coin>> getCoinRecordsByPuzzleHashes(
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

    // TODO: add response mapper
    if (responseData.statusCode != 200) {
      throw Exception('Failed to fetch coin records: ${responseData.body}');
    }

    final coins = (jsonDecode(responseData.body)['coin_records'] as List)
        .map(
          (dynamic value) =>
              Coin.fromChiaCoinRecordJson(value as Map<String, dynamic>),
        )
        .toList();

    return coins;
  }

  Future<void> pushTransaction(SpendBundle spendBundle) async {
    final responseData = await client.sendRequest(
      Uri.parse('push_tx'),
      {'spend_bundle': spendBundle.toJson()},
    );

    print(responseData.body);

    if (responseData.statusCode != 200) {
      throw Exception('Failed to push transaction: ${responseData.body}');
    }
  }

  Future<Coin> getCoinByName(Bytes coinId) async {
    final responseData = await client.sendRequest(Uri.parse('get_coin_record_by_name'), {
      'name': coinId.toHex(),
    });

    if (responseData.statusCode != 200) {
      throw Exception('Failed to push transaction: ${responseData.body}');
    }

    final coinRecordJson = jsonDecode(responseData.body)['coin_record'] as Map<String, dynamic>;
    return Coin.fromChiaCoinRecordJson(coinRecordJson);
  }

  Future<CoinSpend> getPuzzleAndSolution(Bytes coinId, int height) async {
    final responseData = await client.sendRequest(Uri.parse('get_puzzle_and_solution'), {
      'coin_id': coinId.toHex(),
      'height': height,
    });

    if (responseData.statusCode != 200) {
      throw Exception('Failed to get puzzle and solution: ${responseData.body}');
    }

    return CoinSpend.fromJson(jsonDecode(responseData.body)['coin_solution'] as Map<String, dynamic>);
  }
  @override
  String toString() => 'FullNode(${client.baseURL})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullNode &&
          runtimeType == other.runtimeType &&
          baseURL == other.baseURL;

  @override
  int get hashCode => runtimeType.hashCode ^ baseURL.hashCode;
}
