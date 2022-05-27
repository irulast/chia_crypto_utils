import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/tail_database/models/tail_info.dart';

class TailDatabaseApi {
  static const Map<String, String> additionalHeaders = {'x-api-version': '2'};
  static const baseURL = 'https://api.taildatabase.com/enterprise/tail';

  Client get client => Client(baseURL);

  Future<TailInfo> getTailInfo(Puzzlehash assetId) async {
    final response = await client.get(
      Uri.parse(assetId.toHex()),
      additionalHeaders: additionalHeaders,
    );
    return TailInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
