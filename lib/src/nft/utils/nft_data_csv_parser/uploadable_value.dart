import 'dart:io';

import 'package:chia_crypto_utils/src/api/remote_storage/upload/remote_storage_upload_api.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// generic value that can potentially be uploaded to nft storage
class UploadableValue extends Equatable {
  factory UploadableValue(String value) {
    final isUri = Uri.tryParse(value)?.isAbsolute ?? false;
    if (isUri) {
      return UploadableValue.withType(value, StringType.uri);
    }

    final dateTime = DateTime.tryParse(value);

    if (dateTime != null) {
      return UploadableValue.withType(value, StringType.raw);
    }

    final number = num.tryParse(value);

    if (number != null) {
      return UploadableValue.withType(value, StringType.raw);
    }

    if (_isFileName(value)) {
      return UploadableValue.withType(value, StringType.fileName);
    }

    return UploadableValue.withType(value, StringType.raw);
  }

  @visibleForTesting
  const UploadableValue.withType(this._value, this._type);

  static bool _isFileName(String value) {
    return RegExp(r'^.+\..+$').hasMatch(value);
  }

  void assertImage() {
    if (_type != StringType.uri && _type != StringType.fileName) {
      throw ArgumentError(
          'Expected image but got ${_type.name} for value $_value');
    }
  }

  final String _value;
  final StringType _type;

  /// upload value if necassary and return raw string
  Future<String> uploadAndGetRawValue(
    NftStorageUploadApi uploadApi,
    Directory fileDirectory,
  ) async {
    switch (_type) {
      case StringType.raw:
      case StringType.uri:
        return _value;
      case StringType.fileName:
        final fullFileName = '${fileDirectory.path}/$_value';
        final uploadResponse = await uploadApi.uploadFile(File(fullFileName));
        return uploadResponse.link;
    }
  }

  @override
  List<Object?> get props => [_type, _value];
}

class UploadableAttribute extends Equatable {
  const UploadableAttribute({
    required this.type,
    required this.value,
  });

  final String type;
  final UploadableValue value;

  @override
  List<Object?> get props => [type, value];
}

enum StringType {
  uri,
  fileName,
  raw,
}
