import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/coin_market_cap/exceptions/coin_market_cap_api_exception.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('should throw exception for missing API key', () async {
    final coinMarketCapApi = CoinMarketCapApi('');
    expect(
      coinMarketCapApi.getLatestQuoteById,
      throwsA(
        isA<CoinMarketCapApiException>().having(
            (e) => e.message, 'an error message', equals('API key missing.')),
      ),
    );
  });

  test('should throw exception for invalid API key', () async {
    final coinMarketCapApi = CoinMarketCapApi('asldfkjasd');
    expect(
      coinMarketCapApi.getLatestQuoteById,
      throwsA(
        isA<CoinMarketCapApiException>().having((e) => e.message,
            'an error message', equals('This API Key is invalid.')),
      ),
    );
  });

  test(
    'should get CoinMarketCapInfo for XCH',
    () async {
      final coinMarketCapApi = CoinMarketCapApi();
      final xchInfo = await coinMarketCapApi.getLatestQuoteById();
      expect(xchInfo.quote.symbol, 'USD');
      expect(xchInfo.symbol, 'XCH');
    },
    skip:
        'Run from command line with "dart test integration_test/api_test/coin_market_cap_test.dart --run-skipped" Requires valid CoinMarketCap API Key set in environment as CMC_PRO_API_KEY',
  );
}
