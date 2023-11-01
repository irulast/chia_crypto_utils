import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetCoinSpendsByIdsResponse extends ChiaBaseResponse {
  const GetCoinSpendsByIdsResponse({
    required this.coinSpendsMap,
    required super.success,
    required super.error,
  });

  factory GetCoinSpendsByIdsResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    if (chiaBaseResponse.success) {
      return GetCoinSpendsByIdsResponse(
        coinSpendsMap: pick(json, 'coin_solutions').letJsonOrThrow(
          (json) => json.map(
            (coinId, coinSpendJson) => MapEntry(
              Bytes.fromHex(coinId),
              CoinSpend.fromJson(coinSpendJson as Map<String, dynamic>),
            ),
          ),
        ),
        success: chiaBaseResponse.success,
        error: chiaBaseResponse.error,
      );
    } else {
      return GetCoinSpendsByIdsResponse(
        success: chiaBaseResponse.success,
        error: chiaBaseResponse.error,
        coinSpendsMap: const {},
      );
    }
  }
  final Map<Bytes, CoinSpend> coinSpendsMap;
  List<CoinSpend> get coinSpends => coinSpendsMap.values.toList();
}
