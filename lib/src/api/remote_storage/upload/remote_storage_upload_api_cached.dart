import 'dart:async';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/implementations/nft_storage/upload_response.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api_cache.dart';
import 'package:equatable/equatable.dart';

/// Cached decorator for [NftStorageUploadApi]
class NftStorageUploadApiCached implements NftStorageUploadApi {
  NftStorageUploadApiCached._(
    this.delegate, {
    required this.cache,
  });
  final NftStorageUploadCache cache;
  final NftStorageUploadApi delegate;

  static NftStorageUploadApi create(
    NftStorageUploadApi delegate, {
    required NftStorageUploadCache cache,
  }) {
    final localStorageCachedApi = NftStorageUploadApiCached._(delegate, cache: cache);
    return _SynchronizedRequestUploadApi(localStorageCachedApi);
  }

  @override
  Future<NftStorageUploadResponse> uploadBytes(Bytes bytes, {ContentType? contentType}) async {
    final request = RemoteUploadRequest(bytes, contentType);
    final cachedResponse = cache.get(request);
    if (cachedResponse != null) {
      return cachedResponse;
    }

    final response = await delegate.uploadBytes(bytes, contentType: contentType);

    await cache.add(request, response);

    return response;
  }
}

/// Decorator for [NftStorageUploadApi] to prevent duplicate concurrent requests
class _SynchronizedRequestUploadApi implements NftStorageUploadApi {
  _SynchronizedRequestUploadApi(this.delegate);
  final NftStorageUploadApi delegate;

  final _inProgressRequestMap = <String, Completer<NftStorageUploadResponse>>{};

  @override
  Future<NftStorageUploadResponse> uploadBytes(Bytes bytes, {ContentType? contentType}) async {
    final request = RemoteUploadRequest(bytes, contentType);
    final cacheKey = request.cacheKey;
    if (_inProgressRequestMap.containsKey(cacheKey)) {
      return _inProgressRequestMap[cacheKey]!.future;
    }
    final completer = Completer<NftStorageUploadResponse>();
    _inProgressRequestMap[cacheKey] = completer;

    try {
      final result = await delegate.uploadBytes(bytes, contentType: contentType);
      completer.complete(result);
      return result;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inProgressRequestMap.remove(cacheKey);
    }
  }
}

class RemoteUploadRequest extends Equatable {
  const RemoteUploadRequest(this.bytes, this.contentType);

  final Bytes bytes;
  final ContentType? contentType;

  String get cacheKey {
    return '${bytes.sha256Hash().toHex()}${contentType?.mimeType}';
  }

  @override
  List<Object?> get props => [cacheKey];
}
