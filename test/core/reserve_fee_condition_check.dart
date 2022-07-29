import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should determine if condition is reserve fee condition', () {
    final wrongCondition0 = CreateCoinCondition(Program.fromBool(false).hash(), 5);
    final wrongCondition1 =
        AggSigMeCondition(JacobianPoint.generateG1(), Bytes.encodeFromString('yo'));

    final rightCondition = ReserveFeeCondition(5);
    expect(ReserveFeeCondition.isThisCondition(rightCondition.program), true);
    expect(ReserveFeeCondition.isThisCondition(wrongCondition0.program), false);
    expect(ReserveFeeCondition.isThisCondition(wrongCondition1.program), false);
  });
}
