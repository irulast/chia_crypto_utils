import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BlockRecord {
  Bytes headerHash;
  int height;

  BlockRecord({required this.headerHash, required this.height});

  factory BlockRecord.fromJson(Map<String, dynamic> json) {
    return BlockRecord(
      headerHash: Bytes.fromHex(json['header_hash'] as String),
      height: json['height'] as int,
    );
  }
}
