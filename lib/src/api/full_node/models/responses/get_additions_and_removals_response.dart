import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class GetAdditionsAndRemovalsResponse extends ChiaBaseResponse {
  final List<Coin>? additions;
  final List<Coin>? removals;

  const GetAdditionsAndRemovalsResponse({
    this.additions,
    this.removals,
    required bool success,
    required String? error,
  }) : super(
          success: success,
          error: error,
        );

  factory GetAdditionsAndRemovalsResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    if (chiaBaseResponse.success) {
      return GetAdditionsAndRemovalsResponse(
        additions:
            _coinListFromJson(List<Map<String, dynamic>>.from(json['additions'] as Iterable)),
        removals: _coinListFromJson(List<Map<String, dynamic>>.from(json['removals'] as Iterable)),
        success: chiaBaseResponse.success,
        error: chiaBaseResponse.error,
      );
    } else {
      return GetAdditionsAndRemovalsResponse(
        success: chiaBaseResponse.success,
        error: chiaBaseResponse.error,
      );
    }
  }

  static List<Coin> _coinListFromJson(List<Map<String, dynamic>> json) {
    final coins = <Coin>[];
    for (final coinJson in json) {
      coins.add(Coin.fromChiaCoinRecordJson(coinJson));
    }
    return coins;
  }
}
