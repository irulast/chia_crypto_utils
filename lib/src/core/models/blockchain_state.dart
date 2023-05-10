// ignore_for_file: lines_longer_than_80_chars
// TODO(nvjoshi2): add more fields

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BlockchainState {
  BlockchainState({
    required this.difficulty,
    this.peak,
  });

  factory BlockchainState.fromJson(Map<String, dynamic> json) {
    return BlockchainState(
      difficulty: json['difficulty'] as int,
      peak: json['peak'] != null ? Peak.fromJson(json['peak'] as Map<String, dynamic>) : null,
    );
  }
  int difficulty;
  Peak? peak;
}

class Peak {
  Peak({
    required this.farmerPuzzlehash,
    required this.headerHash,
    required this.height,
    required this.timestamp,
  });

  factory Peak.fromJson(Map<String, dynamic> json) {
    return Peak(
      farmerPuzzlehash: Puzzlehash.fromHex(json['farmer_puzzle_hash'] as String),
      headerHash: Bytes.fromHex(json['header_hash'] as String),
      height: json['height'] as int,
      timestamp: json['timestamp'] as int?,
    );
  }
  Puzzlehash farmerPuzzlehash;
  Bytes headerHash;
  int height;
  int? timestamp;

  DateTime? get dateTime =>
      (timestamp != null) ? DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000) : null;
}
