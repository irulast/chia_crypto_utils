import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final parentCoinInfo = Program.fromInt(412).hash();
  final innerPuzzlehash = Program.fromInt(5672).hash();
  const amount = 1004858192;

  final lineageProofsToTest = [
    LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: innerPuzzlehash,
      amount: amount,
    ),
    LineageProof(
      parentCoinInfo: null,
      innerPuzzlehash: innerPuzzlehash,
      amount: amount,
    ),
    LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: null,
      amount: amount,
    ),
    LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: innerPuzzlehash,
      amount: null,
    ),
    const LineageProof(
      parentCoinInfo: null,
      innerPuzzlehash: null,
      amount: amount,
    ),
    LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: null,
      amount: null,
    ),
    LineageProof(
      parentCoinInfo: null,
      innerPuzzlehash: innerPuzzlehash,
      amount: null,
    ),
    const LineageProof(
      parentCoinInfo: null,
      innerPuzzlehash: null,
      amount: null,
    ),
  ];

  test('should serialize and deserialize lineage proofs correctly', () {
    for (final lineageProof in lineageProofsToTest) {
      final serialized = lineageProof.toBytes();
      final deSerialized = LineageProof.fromBytes(serialized);

      expect(deSerialized, lineageProof);
    }
  });
}
