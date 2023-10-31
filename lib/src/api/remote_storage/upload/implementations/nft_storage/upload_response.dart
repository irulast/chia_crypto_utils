import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class NftStorageUploadResponse with ToJsonMixin {
  NftStorageUploadResponse({
    required this.cid,
    this.size,
    this.createdAt,
    this.type,
  });
  factory NftStorageUploadResponse.fromJson(Map<String, dynamic> json) {
    return NftStorageUploadResponse(
      cid: pick(json, 'cid').asStringOrThrow(),
      size: pick(json, 'size').asIntOrNull(),
      createdAt: pick(json, 'created').letStringOrNull(DateTime.parse),
      type: pick(json, 'type').asStringOrNull(),
    );
  }

  final String cid;

  String get link => 'https://$cid.ipfs.nftstorage.link/';
  final int? size;
  final DateTime? createdAt;
  final String? type;

  @override
  Map<String, dynamic> toJson() {
    return {
      'cid': cid,
      'size': size,
      'created': createdAt?.toIso8601String(),
      'type': type,
    };
  }
}

class NftStorageUploadErrorResponse with ToJsonMixin {
  NftStorageUploadErrorResponse({
    required this.name,
    required this.message,
  });
  factory NftStorageUploadErrorResponse.fromJson(Map<String, dynamic> json) {
    return NftStorageUploadErrorResponse(
      name: pick(json, 'name').asStringOrNull(),
      message: pick(json, 'message').asStringOrNull(),
    );
  }

  final String? name;
  final String? message;

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'message': message,
    };
  }
}

class NftStorageUploadException implements Exception {
  NftStorageUploadException(this.errorResponse);
  final NftStorageUploadErrorResponse errorResponse;

  @override
  String toString() {
    return 'NftStorageUploadException{errorResponse: ${errorResponse.toSerializedJson()}}';
  }
}
