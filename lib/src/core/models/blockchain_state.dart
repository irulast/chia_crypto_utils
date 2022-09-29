// ignore_for_file: lines_longer_than_80_chars
// TODO(nvjoshi2): add more fields

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BlockchainState {
  int difficulty;
  Peak? peak;

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
}

class Peak {
  Bytes farmerPuzzleHash;
  Bytes headerHash;
  int height;

  Peak({
    required this.farmerPuzzleHash,
    required this.headerHash,
    required this.height,
  });

  factory Peak.fromJson(Map<String, dynamic> json) {
    return Peak(
      farmerPuzzleHash: Bytes.fromHex(json['farmer_puzzle_hash'] as String),
      headerHash: Bytes.fromHex(json['header_hash'] as String),
      height: json['height'] as int,
    );
  }
}
