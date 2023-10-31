import 'dart:io';

import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api.dart';
import 'package:test/test.dart';

void main() {
  test('should upload to nft storage', () async {
    final storage = NftStorageUploadApi(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDUyYjUxMDJmOWI5Y2NBMTREMDBjMjNjY2QwOTE2YTBBQTREMGNmMjQiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTY4OTAwNTQ0OTg3NCwibmFtZSI6ImJ1bGstbWludGluZy10ZXN0In0.5qdP1qwH4_SOoYCRrIdoXK0RDqzweXanzhxUCP8YH-g',
    );

    final response = await storage.uploadFile(File('./test/assets/vosk_coin.png'));
    print(response.link);
    print(response.toJson());
  });
}
