import 'dart:async';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/http_exceptions/too_many_requests.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/implementations/nft_storage/upload_response.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api_cached.dart';
import 'package:http/http.dart';

/// Decorator for [NftStorageUploadApi] that retries requests with binary backoff
class NftStorageUploadApiWithBinaryBackoff implements NftStorageUploadApi {
  NftStorageUploadApiWithBinaryBackoff(
    this.delegate, {
    this.initialBackoffDuration = const Duration(seconds: 30),
  });
  final NftStorageUploadApi delegate;

  final Duration initialBackoffDuration;

  @override
  Future<NftStorageUploadResponse> uploadBytes(Bytes bytes,
      {ContentType? contentType}) async {
    final request = RemoteUploadRequest(bytes, contentType);

    final response =
        await _completeRequestWithBackoff(request, initialBackoffDuration);
    return response;
  }

  static const _maxClientExceptions = 5;

  Future<NftStorageUploadResponse> _completeRequestWithBackoff(
    RemoteUploadRequest request,
    Duration backoffDuration, {
    int clientExceptionCount = 0,
  }) async {
    try {
      final response = await delegate.uploadBytes(request.bytes,
          contentType: request.contentType);
      return response;
    } on TooManyRequestsException {
      LoggingContext().info(
          'Too many requests: backing off nft storage for $backoffDuration');
      await Future<void>.delayed(backoffDuration);
      return _completeRequestWithBackoff(
        request,
        backoffDuration * 2,
      );
    } on ClientException catch (e) {
      if (clientExceptionCount >= _maxClientExceptions) {
        LoggingContext().info('max upload socket exceptions reached');
        rethrow;
      }
      LoggingContext().info(
          'Client exception:${e.message}, backing off nft storage for $backoffDuration');
      await Future<void>.delayed(backoffDuration);
      return _completeRequestWithBackoff(
        request,
        backoffDuration,
        clientExceptionCount: clientExceptionCount + 1,
      );
    }
  }
}
