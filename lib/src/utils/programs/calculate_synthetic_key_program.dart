part of 'programs.dart';

// from chia/wallet/puzzles/calculate_synthetic_public_key.clvm
final calculateSyntheticKeyProgram = Program.deserializeHexFile(
  'lib/src/core/puzzles/calculate_synthetic_public_key/calculate_synthetic_public_key.clvm.hex',
);
