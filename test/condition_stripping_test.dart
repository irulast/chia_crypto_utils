import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() {
  final createCoinConditionProgram = CreateCoinCondition(
    Puzzlehash.fromHex(
        '4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a'),
    200,
    memos: [
      Puzzlehash.fromHex(
          '9dcf97a184f32623d11a73124ceb99a5709b083721e878a16d78f596718ba7b2')
    ],
  ).toProgram();
  print(createCoinConditionProgram.first());
  print(createCoinConditionProgram.rest().first());
  print(createCoinConditionProgram.rest().rest().first());
}
