import 'package:meta/meta.dart';

@immutable
class ChiaBaseResponse {
  final String? error;
  final bool success;

  const ChiaBaseResponse({
    required this.error,
    required this.success,
  });

  factory ChiaBaseResponse.fromJson(Map<String, dynamic> json) {
    return ChiaBaseResponse(
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }

  @override
  String toString() => 'ChiaBaseResponse(success: $success, error: $error)';
}
