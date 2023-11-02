import 'dart:convert';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/http_exceptions/too_many_requests.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/implementations/nft_storage/upload_response.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;

class NftStorageUploadApiI implements NftStorageUploadApi {
  NftStorageUploadApiI(this._apiKey);

  final _uri = Uri.https('api.nft.storage', '/upload');

  final String _apiKey;

  @override
  Future<NftStorageUploadResponse> uploadBytes(
    Bytes bytes, {
    ContentType? contentType,
  }) async {
    final response = await http.post(
      _uri,
      body: bytes.byteList,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        if (contentType != null) 'Content-Type': contentType.value,
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    _validateResponse(response.statusCode, body);
    final result =
        NftStorageUploadResponse.fromJson(pick(body, 'value').asJsonOrThrow());

    return result;
  }

  void _validateResponse(int statusCode, Map<String, dynamic> body) {
    switch (statusCode) {
      case 200:
        return;
      case 429:
        throw TooManyRequestsException();
    }
    print(statusCode);
    print(body);
    final isOk = pick(body, 'ok').asBoolOrFalse();

    if (!isOk) {
      final error = pick(body, 'error').asJsonOrNull();
      if (error != null) {
        throw NftStorageUploadException(
          NftStorageUploadErrorResponse.fromJson(error),
        );
      }
      throw Exception('Nft Upload error: $body');
    }
  }
}
