// from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.clvm
import 'package:chia_utils/chia_crypto_utils.dart';

final standardTransactionPuzzle = Program.deserializeHexFile(
  'lib/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex',
);

// from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.py
final defaultHiddenPuzzle = Program.parse('(=)');

// from chia/wallet/puzzles/calculate_synthetic_public_key.clvm
final calculateSyntheticKeyProgram = Program.deserializeHexFile(
  'lib/src/core/puzzles/calculate_synthetic_public_key/calculate_synthetic_public_key.clvm.hex',
);
