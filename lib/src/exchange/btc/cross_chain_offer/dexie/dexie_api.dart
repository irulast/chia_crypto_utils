import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DexieApi {
  Client get client => Client(url);
  String get url => 'https://api.dexie.space/v1';
  String get testnetUrl => 'https://api-testnet.dexie.space/v1';

  Future<DexiePostOfferResponse> postOffer(String serializedOfferFile) async {
    final response = await client.post(Uri.parse('ccoffers'), {
      'offer': serializedOfferFile,
    });

    return DexiePostOfferResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DexieInspectOfferResponse> inspectOffer(String id) async {
    final response = await client.get(Uri.parse('ccoffers/$id'));

    return DexieInspectOfferResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
