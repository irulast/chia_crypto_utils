import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BlockRecord {
  BlockRecord({required this.headerHash, required this.height, required this.timestamp});
  factory BlockRecord.fromJson(Map<String, dynamic> json) {
    return BlockRecord(
      headerHash: Bytes.fromHex(json['header_hash'] as String),
      height: json['height'] as int,
      timestamp: json['timestamp'] as int?,
    );
  }

  Bytes headerHash;
  int height;
  int? timestamp;

  DateTime? get dateTime =>
      (timestamp != null) ? DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000) : null;
}
