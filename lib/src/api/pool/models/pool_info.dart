import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PoolInfo {
  const PoolInfo({
    required this.description,
    required this.fee,
    required this.logoUrl,
    required this.minimumDifficulty,
    required this.name,
    required this.protocolVersion,
    required this.relativeLockHeight,
    required this.targetPuzzlehash,
    required this.authenticationTokenTimeout,
  });
  factory PoolInfo.fromJson(Map<String, dynamic> json) {
    return PoolInfo(
      description: json['description'] as String,
      fee: json['fee'] is double ? json['fee'].toString() : json['fee'] as String,
      logoUrl: json['logo_url'] as String,
      minimumDifficulty: json['minimum_difficulty'] as num,
      name: json['name'] as String,
      protocolVersion: json['protocol_version'] as int,
      relativeLockHeight: json['relative_lock_height'] as int,
      targetPuzzlehash: Puzzlehash.fromHex(json['target_puzzle_hash'] as String),
      authenticationTokenTimeout: json['authentication_token_timeout'] as int,
    );
  }
  final String description;
  final String fee;
  final String logoUrl;
  final num minimumDifficulty;
  final String name;
  final int protocolVersion;
  final int relativeLockHeight;
  final Puzzlehash targetPuzzlehash;
  final int authenticationTokenTimeout;

  @override
  String toString() => 'PoolInfo(name: $name, description: $description, fee: $fee, minimumDifficulty: $minimumDifficulty, protocolVersion: $protocolVersion, relativeLockHeight: $relativeLockHeight, targetPuzzlehash: $targetPuzzlehash, authenticationTokenTimeout: $authenticationTokenTimeout, logoUrl: $logoUrl)';
}
