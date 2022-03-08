import 'package:chia_utils/src/clvm/program.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


Future<void> main() async {
  test('Should deserialize program from hex file', () {
    const compiledClvm = '(a (q 2 (i 11 (q 2 (i (= 5 (point_add 11 (pubkey_for_exp (sha256 11 (a 6 (c 2 (c 23 ()))))))) (q 2 23 47) (q 8)) 1) (q 4 (c 4 (c 5 (c (a 6 (c 2 (c 23 ()))) ()))) (a 23 47))) 1) (c (q 50 2 (i (l 5) (q 11 (q . 2) (a 6 (c 2 (c 9 ()))) (a 6 (c 2 (c 13 ())))) (q 11 (q . 1) 5)) 1) 1))';
    final program = Program.deserializeHexFile('lib/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex');
    expect(program.toSource(), compiledClvm);
  });
}