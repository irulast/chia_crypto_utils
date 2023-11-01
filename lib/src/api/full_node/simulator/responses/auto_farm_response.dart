import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class AutofarmResponse extends ChiaBaseResponse {
  const AutofarmResponse({
    required this.isAutofarming,
    required super.success,
    required super.error,
  });

  factory AutofarmResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return AutofarmResponse(
      isAutofarming: pick(json, 'auto_farm_enabled').asBoolOrThrow(),
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
  final bool isAutofarming;

  @override
  String toString() =>
      'AutofarmResponse(isAutofarming: $isAutofarming, success: $success, error: $error)';
}
