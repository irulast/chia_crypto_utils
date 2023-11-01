import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  List<Puzzlehash> getNPuzzlehashes(int n) {
    final puzzlehashes = <Puzzlehash>[];
    for (var i = 0; i < n; i++) {
      puzzlehashes.add(Program.fromInt(i).hash());
    }
    return puzzlehashes;
  }

  test('should get random puzzlehash', () {
    expect(() => getNPuzzlehashes(0).random,
        throwsA(const TypeMatcher<StateError>()));
    for (var i = 1; i < 50; i++) {
      getNPuzzlehashes(i).random;
    }
  });
}
