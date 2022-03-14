
# $1: name of the file to generate
# s3: name of the program variable
# $2: path of the clvm program
generateFile() {
  echo "// ignore_for_file: lines_longer_than_80_chars

part of 'programs.dart';

// program: $3
final $2 = Program.deserializeHex(
  '$(cat $3)',
);" > lib/src/utils/programs/$1
}

generateFile standard_transaction_puzzle.dart standardTransactionPuzzle lib/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex
generateFile calculate_synthetic_key_program.dart calculateSyntheticKeyProgram lib/src/core/puzzles/calculate_synthetic_public_key/calculate_synthetic_public_key.clvm.hex