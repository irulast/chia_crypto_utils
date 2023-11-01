import 'package:deep_pick/deep_pick.dart';

class DexieInspectOfferResponse {
  const DexieInspectOfferResponse({
    required this.success,
    required this.serializedOffer,
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
      success: pick(json, 'success').asBoolOrTrue(),
      offerJson: offerJson,
      errorMessage: errorMessage,
      serializedOffer: pick(json, 'offer', 'offer').asStringOrNull(),
    );
  }

  final bool success;
  final Map<String, dynamic>? offerJson;
  final String? errorMessage;
  final String? serializedOffer;
}
