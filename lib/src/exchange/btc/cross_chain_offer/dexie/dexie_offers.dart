import 'dart:convert';

import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie_post_offer_response.dart';
import 'package:http/http.dart' as http;

class DexieOffers {
  String get url => 'https://api.dexie.space/v1/ccoffers';

  Future<DexiePostOfferResponse> postOffer(String serializedOfferFile) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    final body = '{"offer":$serializedOfferFile}';

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    return DexiePostOfferResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
