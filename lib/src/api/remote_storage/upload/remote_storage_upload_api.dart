import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/http_exceptions/too_many_requests.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/implementations/nft_storage/nft_storage_upload_api.dart';
import 'package:chia_crypto_utils/src/api/remote_storage/upload/implementations/nft_storage/upload_response.dart';

abstract class NftStorageUploadApi {
  factory NftStorageUploadApi(String apiKey) => NftStorageUploadApiI(apiKey);

  /// throws [TooManyRequestsException], [NftStorageUploadException]
  Future<NftStorageUploadResponse> uploadBytes(Bytes bytes, {ContentType? contentType});
}

extension UploadTypesX on NftStorageUploadApi {
  Future<NftStorageUploadResponse> uploadJson(Map<String, dynamic> json) async {
    return uploadBytes(
      Bytes.encodeFromString(ToJsonMixin.indentEncoder.convert(json)),
      contentType: ContentType.json,
    );
  }

  Future<NftStorageUploadResponse> uploadFile(File file, {ContentType? contentType}) {
    return uploadBytes(Bytes(file.readAsBytesSync()), contentType: contentType);
  }
}
