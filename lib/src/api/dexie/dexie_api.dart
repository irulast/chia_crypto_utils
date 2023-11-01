import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class DexieOffersApi {
  Client get client => Client(url);
  String get url => 'https://api.dexie.space/v1';
  String get testnetUrl => 'https://api-testnet.dexie.space/v1';

  Future<DexieOffer?> inspectOffer(String id) async {
    final response = await client.get(Uri.parse('offers/$id'));

    if (response.statusCode == 404) {
      return null;
    }
    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
    final baseResponse = DexieBaseResponse.fromJson(bodyJson);

    if (!baseResponse.success) {
      throw DexieApiErrorException(errorMessage: baseResponse.errorMessage);
    }

    return DexieOffer.fromJson(pick(bodyJson, 'offer').letJsonOrThrow((json) => json));
  }
}

class DexieBaseResponse {
  const DexieBaseResponse({
    required this.success,
    required this.errorMessage,
  });

  factory DexieBaseResponse.fromJson(Map<String, dynamic> json) {
    return DexieBaseResponse(
      success: pick(json, 'success').asBoolOrTrue(),
      errorMessage: pick(json, 'error_message').asStringOrNull(),
    );
  }
  final bool success;
  final String? errorMessage;
}

class DexieOffer {
  DexieOffer(this.serializedOffer);
  factory DexieOffer.fromJson(Map<String, dynamic> json) {
    return DexieOffer(pick(json, 'offer').asStringOrThrow());
  }

  final String serializedOffer;
}

class DexieApiErrorException implements Exception {
  const DexieApiErrorException({
    required this.errorMessage,
  });
  final String? errorMessage;

  @override
  String toString() {
    return 'DexieApiErrorException{errorMessage: $errorMessage}';
  }
}
