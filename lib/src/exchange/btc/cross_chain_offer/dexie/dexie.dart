import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie_post_offer_response.dart';

class Dexie {
  Client get client => Client(url);
  // String get url => 'https://api-testnet.dexie.space/v1';
  String get url => 'https://api.dexie.space/v1';

  Future<DexiePostOfferResponse> postOffer(String serializedOfferFile) async {
    final response = await client.post(Uri.parse('ccoffers'), {
      'offer': serializedOfferFile,
    });

    return DexiePostOfferResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
