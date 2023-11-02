import 'dart:convert';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/coin_market_cap/exceptions/coin_market_cap_api_exception.dart';
import 'package:chia_crypto_utils/src/api/coin_market_cap/models/cryptocurrency.dart';
import 'package:chia_crypto_utils/src/api/coin_market_cap/models/status.dart';

class CoinMarketCapApi {
  CoinMarketCapApi([String? apiKey]) {
    this.apiKey = apiKey ?? (Platform.environment['CMC_PRO_API_KEY'] ?? '');
  }
  static const String baseURL = 'https://pro-api.coinmarketcap.com';
  static const String xchCoinMarketCapId = '9258';
  late String apiKey;

  Client get client => Client(baseURL);

  Future<Cryptocurrency> getLatestQuoteById([
    String convertSymbol = 'USD',
  ]) async {
    final response = await client.get(
      Uri.parse('v2/cryptocurrency/quotes/latest'),
      queryParameters: <String, dynamic>{
        'id': xchCoinMarketCapId,
        'convert': convertSymbol
      },
      additionalHeaders: {'X-CMC_PRO_API_KEY': apiKey},
    );
    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final status =
        Status.fromJson(responseJson['status'] as Map<String, dynamic>);
    if (status.errorCode == 0) {
      final data = responseJson['data'] as Map<String, dynamic>;
      final crypto = data[xchCoinMarketCapId] as Map<String, dynamic>;
      return Cryptocurrency.fromJson(crypto);
    } else {
      throw CoinMarketCapApiException(message: status.errorMessage);
    }
  }
}
