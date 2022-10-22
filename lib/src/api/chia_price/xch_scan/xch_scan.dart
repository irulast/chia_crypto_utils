import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class XchScan implements ChiaPriceProvider {
  Client get client => Client(url);

  String get url => 'https://xchscan.com/api';

  @override
  Future<XchScanResponse> getChiaPrice() async {
    final response = await client.get(
      Uri.parse('chia-price'),
    );

    return XchScanResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
