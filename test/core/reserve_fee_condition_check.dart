import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should determine if condition is reserve fee condition', () {
    final createCoinCondition = CreateCoinCondition(Program.fromBool(false).hash(), 5);
    final aggSigMeCondition =
        AggSigMeCondition(JacobianPoint.generateG1(), Bytes.encodeFromString('yo'));

    final reserveFeeCondition = ReserveFeeCondition(5);

    expect(ReserveFeeCondition.isThisCondition(reserveFeeCondition.program), true);
    expect(ReserveFeeCondition.isThisCondition(aggSigMeCondition.program), false);
    expect(ReserveFeeCondition.isThisCondition(createCoinCondition.program), false);

    final serialized = reserveFeeCondition.program;
    final deserialized = ReserveFeeCondition.fromProgram(serialized);

    expect(deserialized.feeAmount, reserveFeeCondition.feeAmount);
    expect(serialized, deserialized.program);

  });
}
