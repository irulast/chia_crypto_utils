import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final poolInfo = PoolInfo.fromJson(
    jsonDecode(
      '{"description": "The Most Advanced Mining Pool - Featuring FlexFarmer, the future of the farming", "fee": "0.7%", "logo_url": "https://static.flexpool.io/assets/brand/light.svg", "minimum_difficulty": 1, "name": "Flexpool.io", "protocol_version": 1, "relative_lock_height": 100, "target_puzzle_hash": "0x6bde1e0c6f9d3b93dc5e7e878723257ede573deeed59e3b4a90f5c86de1a0bd3", "authentication_token_timeout": 5}',
    ) as Map<String, dynamic>,
  );

  test('should create from json response', () {
    expect(
      poolInfo.description,
      'The Most Advanced Mining Pool - Featuring FlexFarmer, the future of the farming',
    );
    expect(
      poolInfo.fee,
      '0.7%',
    );
    expect(
      poolInfo.logoUrl,
      'https://static.flexpool.io/assets/brand/light.svg',
    );
    expect(
      poolInfo.minimumDifficulty,
      1,
    );
    expect(
      poolInfo.name,
      'Flexpool.io',
    );
    expect(
      poolInfo.protocolVersion,
      1,
    );
    expect(
      poolInfo.relativeLockHeight,
      100,
    );
    expect(
      poolInfo.targetPuzzlehash,
      Puzzlehash.fromHex('0x6bde1e0c6f9d3b93dc5e7e878723257ede573deeed59e3b4a90f5c86de1a0bd3'),
    );
    expect(
      poolInfo.authenticationTokenTimeout,
      5,
    );
  });
}
