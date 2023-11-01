import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final pk = JacobianPoint.fromHexG1(
    '97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb',
  );

  final expectedPuzzlehash =
      Puzzlehash.fromHex('48068eb6150f738fe90a001c562f0c4b769b7d64a59915aa8c0886b978e38137');
  test('should get correct puzzle for pk', () {
    final puzzleHash = getPuzzleFromPk(pk).hash();
    expect(puzzleHash, expectedPuzzlehash);
  });
}
