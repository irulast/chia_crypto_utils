import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should determine if condition is reserve fee condition', () {
    final createCoinCondition = CreateCoinCondition(Program.fromBool(false).hash(), 5);
    final aggSigMeCondition =
        AggSigMeCondition(JacobianPoint.generateG1(), Bytes.encodeFromString('yo'));

    final reserveFeeCondition = ReserveFeeCondition(5);

    expect(ReserveFeeCondition.isThisCondition(reserveFeeCondition.toProgram()), true);
    expect(ReserveFeeCondition.isThisCondition(aggSigMeCondition.toProgram()), false);
    expect(ReserveFeeCondition.isThisCondition(createCoinCondition.toProgram()), false);

    final serialized = reserveFeeCondition.toProgram();
    final deserialized = ReserveFeeCondition.fromProgram(serialized);

    expect(deserialized.feeAmount, reserveFeeCondition.feeAmount);
    expect(serialized, deserialized.toProgram());
  });
}
