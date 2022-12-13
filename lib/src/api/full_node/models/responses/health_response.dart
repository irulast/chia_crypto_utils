import 'package:meta/meta.dart';

@immutable
class HealthResponse {
  final String success;

  const HealthResponse({
    required this.success,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      success: json['success'] as String,
    );
  }
  Map<String, dynamic> toJson() => <String, dynamic>{
        'success': success,
      };

  @override
  String toString() => 'HealthResponse(success: $success)';
}
