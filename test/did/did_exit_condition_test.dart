import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should fail on invalid program', () {
    expect(
      () => DidExitCondition.fromProgram(Program.fromInt(1)),
      throwsA(isA<InvalidConditionCastException>()),
    );
  });
}
