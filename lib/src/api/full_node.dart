import 'dart:convert';

import 'package:chia_utils/src/api/client.dart';
import 'package:chia_utils/src/core/models/coin_record.dart';
import 'package:chia_utils/src/core/models/spend_bundle.dart';



class FullNode {
  late Client client;

  FullNode(String baseURL) {
    client = Client(baseURL);
  }

  Future<List<CoinRecord>> getCoinRecordsByPuzzleHashes(List<String>  puzzlehashes, {int? startHeight, int? endHeight, bool includeSpentCoins = false}) async {
    Map<String, dynamic> body={
      'puzzle_hashes': puzzlehashes,
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
    final responseData = await client.sendRequest(Uri.parse('get_coin_records_by_puzzle_hashes'), body);

    // TODO: add response mapper
    if (responseData.statusCode != 200) {
      throw Exception('Failed to fetch coin records: ${responseData.body}');
    }
    final coinRecords = (jsonDecode(responseData.body)['coin_records'] as List)
            .map((value) => CoinRecord.fromJson(value))
            .toList();


    return coinRecords;
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