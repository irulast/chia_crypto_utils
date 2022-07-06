import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/chia_price/chia_pricer.dart';
import 'package:chia_crypto_utils/src/api/chia_price/xch_scan/xch_scan_response.dart';

class XchScan implements ChiaPricer {
  Client get client => Client(url);

  @override
  String get url => 'https://xchscan.com/api';

  @override
  Future<double> getChiaPriceUsd() async {
    final response = await client.get(
      Uri.parse('chia-price'),
    );

    return XchScanResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    ).priceUsd;
  }
}
