class ChiaBaseResponse {
  String? error;
  bool success;

  ChiaBaseResponse({
    required this.error, 
    required this.success,
  });

  factory ChiaBaseResponse.fromJson(Map<String, dynamic> json) {
    return ChiaBaseResponse(
      error: json['error'] as String?,
      success: json['success'] as bool,
    );
  }
}
