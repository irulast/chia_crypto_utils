import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class GetAdditionsAndRemovalsWithHintsResponse extends ChiaBaseResponse {
  const GetAdditionsAndRemovalsWithHintsResponse({
    this.additions,
    this.removals,
    required super.success,
    required super.error,
  });

  factory GetAdditionsAndRemovalsWithHintsResponse.fromJson(
      Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    if (chiaBaseResponse.success) {
      return GetAdditionsAndRemovalsWithHintsResponse(
        additions: _coinListFromJson(
            List<Map<String, dynamic>>.from(json['additions'] as Iterable)),
        removals: _coinListFromJson(
            List<Map<String, dynamic>>.from(json['removals'] as Iterable)),
        success: chiaBaseResponse.success,
        error: chiaBaseResponse.error,
      );
    } else {
      return GetAdditionsAndRemovalsWithHintsResponse(
        success: chiaBaseResponse.success,
        error: chiaBaseResponse.error,
      );
    }
  }
  final List<CoinWithHint>? additions;
  final List<CoinWithHint>? removals;

  static List<CoinWithHint> _coinListFromJson(List<Map<String, dynamic>> json) {
    final coins = <CoinWithHint>[];
    for (final coinJson in json) {
      coins.add(CoinWithHint.fromChiaCoinRecordJson(coinJson));
    }
    return coins;
  }
}
