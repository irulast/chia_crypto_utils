import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class NamesdaoApi {
  factory NamesdaoApi() => _NamesdaoApi();
  Future<NameInfo?> getNameInfo(String name);
  Future<NameRegistrationInfo> getRegistrationInfo();
}

class _NamesdaoApi implements NamesdaoApi {
  static const baseURL = 'https://namesdaolookup.xchstorage.com';

  Client get client => Client(baseURL);

  @override
  Future<NameInfo?> getNameInfo(String name) async {
    var normalName = name.toLowerCase();

    // Remove the suffix if present
    const suffix = '.xch';
    if (normalName.endsWith(suffix)) {
      normalName = normalName.substring(0, name.length - suffix.length);
    }

    final response = await client.get(
      Uri.parse('$normalName.json'),
    );

    if (response.statusCode == 403 || response.statusCode == 404) {
      return null;
    }

    return NameInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<NameRegistrationInfo> getRegistrationInfo() async {
    final response = await Client('https://api.namesdao.org/v1').get(Uri.parse('info'));

    return NameRegistrationInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
