import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/chia_price/xch_scan/xch_scan_response.dart';
// TODO(nvjoshi2): implement chia pricer interface
class XchScan {
  Client get client => Client(url);

  String get url => 'https://xchscan.com/api';

  Future<XchScanResponse> getChiaPrice() async {
    final response = await client.get(
      Uri.parse('chia-price'),
    );

    return XchScanResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
