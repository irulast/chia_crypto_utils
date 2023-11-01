import 'dart:convert';
import 'dart:io';

import 'package:chia_crypto_utils/src/api/remote_storage/upload/implementations/nft_storage/upload_response.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api_cached.dart';
import 'package:synchronized/synchronized.dart';

abstract class NftStorageUploadCache {
  Future<void> add(
      RemoteUploadRequest request, NftStorageUploadResponse response);

  NftStorageUploadResponse? get(RemoteUploadRequest request);
}

class NftStorageApiJsonCache implements NftStorageUploadCache {
  NftStorageApiJsonCache(this.jsonFile);

  final File jsonFile;

  void init() {
    if (!jsonFile.existsSync()) {
      jsonFile
        ..createSync()
        ..writeAsStringSync('{}');
    }
  }

  final _lock = Lock();

  Map<String, dynamic> get _currentJson {
    final json = jsonFile.readAsStringSync();
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded;
  }

  @override
  Future<void> add(
      RemoteUploadRequest request, NftStorageUploadResponse response) {
    return _lock.synchronized(() async {
      final json = _currentJson;
      json[request.cacheKey] = response.toJson();
      await jsonFile.writeAsString(jsonEncode(json));
    });
  }

  @override
  NftStorageUploadResponse? get(RemoteUploadRequest request) {
    final key = request.cacheKey;
    final current = _currentJson;
    if (!current.containsKey(key)) {
      return null;
    }
    return NftStorageUploadResponse.fromJson(
        current[key] as Map<String, dynamic>);
  }
}
