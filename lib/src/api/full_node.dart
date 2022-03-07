import 'dart:convert';

import 'package:chia_utils/src/api/client.dart';
import 'package:chia_utils/src/core/models/coin.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';
import 'package:chia_utils/src/core/models/spend_bundle.dart';

class FullNode {
  late Client client;

  FullNode(String baseURL) {
    client = Client(baseURL);
  }

  Future<List<Coin>> getCoinRecordsByPuzzleHashes(List<Puzzlehash> puzzlehashes,
      {int? startHeight,
      int? endHeight,
      bool includeSpentCoins = false}) async {
    final body = <String, dynamic> {
      'puzzle_hashes': puzzlehashes.map((ph) => ph.hex).toList(),
    };
    if (startHeight != null) {
      body['start_height'] = startHeight;
    }
    if (startHeight != null) {
      body['end_height'] = endHeight;
    }
    if (startHeight != null) {
      body['include_spent_coins'] = includeSpentCoins;
    }
    final responseData = await client.sendRequest(
        Uri.parse('get_coin_records_by_puzzle_hashes'), body);

    // TODO: add response mapper
    if (responseData.statusCode != 200) {
      throw Exception('Failed to fetch coin records: ${responseData.body}');
    }
    final coins = (jsonDecode(responseData.body)['coin_records'] as List)
        .map((dynamic value) => Coin.fromChiaCoinRecordJson(value as Map<String, dynamic>))
        .toList();

    return coins;
  }

  Future<void> pushTransaction(SpendBundle spendBundle) async {
    final responseData = await client.sendRequest(Uri.parse('push_tx'), {
      'spend_bundle': spendBundle.toJson()
    });

    if (responseData.statusCode != 200) {
      throw Exception('Failed to push transaction: ${responseData.body}');
    }
  }
}
