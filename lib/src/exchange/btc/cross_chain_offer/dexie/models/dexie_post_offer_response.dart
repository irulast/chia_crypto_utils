class DexiePostOfferResponse {
  DexiePostOfferResponse({
    required this.success,
    this.id,
    this.known,
    this.offerJson,
    this.errorMessage,
  });
  factory DexiePostOfferResponse.fromJson(Map<String, dynamic> json) {
    String? id;
    if (json.containsKey('id')) {
      id = json['id'] as String;
    }

    Map<String, dynamic>? offerJson;
    if (json.containsKey('offer')) {
      offerJson = json['offer'] as Map<String, dynamic>;
    }

    String? errorMessage;
    if (json.containsKey('error_message')) {
      errorMessage = json['error_message'] as String;
    }

    return DexiePostOfferResponse(
      success: json['success'] as bool,
      id: id,
      offerJson: offerJson,
      errorMessage: errorMessage,
    );
  }

  bool success;
  String? id;
  bool? known;
  Map<String, dynamic>? offerJson;
  String? errorMessage;
}
