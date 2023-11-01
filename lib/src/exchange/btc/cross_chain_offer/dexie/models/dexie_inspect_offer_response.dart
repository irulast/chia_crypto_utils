class DexieInspectOfferResponse {
  DexieInspectOfferResponse({
    required this.success,
    this.offerJson,
    this.errorMessage,
  });
  factory DexieInspectOfferResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? offerJson;
    if (json.containsKey('offer')) {
      offerJson = json['offer'] as Map<String, dynamic>;
    }

    String? errorMessage;
    if (json.containsKey('error_message')) {
      errorMessage = json['error_message'] as String;
    }

    return DexieInspectOfferResponse(
      success: json['success'] as bool,
      offerJson: offerJson,
      errorMessage: errorMessage,
    );
  }

  bool success;
  Map<String, dynamic>? offerJson;
  String? errorMessage;
}
