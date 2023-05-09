import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class TailDatabaseApi {
  factory TailDatabaseApi() => _TailDatabaseApi();
  Future<TailInfo> getTailInfo(Puzzlehash assetId);
}

class _TailDatabaseApi implements TailDatabaseApi {
  // static const Map<String, String> additionalHeaders = {'x-api-version': '2'};
  static const baseURL = 'https://mainnet-api.taildatabase.com/tail';

  Client get client => Client(baseURL);

  @override
  Future<TailInfo> getTailInfo(Puzzlehash assetId) async {
    final response = await client.get(
      Uri.parse(assetId.toHex()),
      // additionalHeaders: additionalHeaders,
    );
    return TailInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
