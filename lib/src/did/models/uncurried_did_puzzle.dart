import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class UncurriedDidPuzzle {
  const UncurriedDidPuzzle({
    required this.innerPuzzle,
    required this.singletonStructure,
    required this.did,
  });

  factory UncurriedDidPuzzle.fromProgram(Program fullPuzzle) {
    final uncurried = maybeFromProgram(fullPuzzle);
    if (uncurried == null) {
      throw InvalidDidException();
    }

    return uncurried;
  }

  static UncurriedDidPuzzle? maybeFromProgram(Program fullPuzzle) {
    final uncurriedPuzzle = fullPuzzle.uncurry();
    return maybeFromUncurriedProgram(uncurriedPuzzle);
  }

  static UncurriedDidPuzzle? maybeFromUncurriedProgram(
    ModAndArguments uncurriedPuzzle,
  ) {
    if (uncurriedPuzzle.mod != singletonTopLayerV1Program) {
      return null;
    }
    final arguments = uncurriedPuzzle.arguments;

    final singletonStructure = arguments[0];
    final parentInnerPuzzle = arguments[1];
    final did = singletonStructure.rest().first().atom;

    final uncurriedInnerPuzzle =
        UncurriedDidInnerPuzzle.maybeFromProgram(parentInnerPuzzle);
    if (uncurriedInnerPuzzle == null) {
      return null;
    }

    return UncurriedDidPuzzle(
      innerPuzzle: uncurriedInnerPuzzle,
      singletonStructure: singletonStructure,
      did: did,
    );
  }

  final UncurriedDidInnerPuzzle innerPuzzle;
  final Program singletonStructure;
  final Bytes did;
}
