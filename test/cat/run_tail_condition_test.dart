import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/models/conditions/run_tail_condition.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should return the desired string form', () {
    final runTailCondition =
        RunTailCondition(Program.fromInt(1234567890), Program.fromInt(1234567890));
    expect(
      runTailCondition.toString(),
      'RunTailCondition(code: ${RunTailCondition.conditionCode}, '
      'tail: ${runTailCondition.tail}, '
      'tailSolution: ${runTailCondition.tailSolution})',
    );
  });
}
