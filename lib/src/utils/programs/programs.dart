// from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.clvm
import 'package:chia_utils/chia_crypto_utils.dart';

part 'standard_transaction_puzzle.dart';
part 'calculate_synthetic_key_program.dart';

// from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.py
final defaultHiddenPuzzle = Program.parse('(=)');
