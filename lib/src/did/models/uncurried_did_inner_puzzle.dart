import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class UncurriedDidInnerPuzzle {
  UncurriedDidInnerPuzzle._({
    required this.p2Puzzle,
    required this.backUpIdsHashProgram,
    required this.numberOfVerificationsRequiredProgram,
    required this.singletonStructureProgram,
    required this.metadataProgram,
  });

  factory UncurriedDidInnerPuzzle.fromProgram(Program innerPuzzle) {
    final uncurried = maybeFromProgram(innerPuzzle);
    if (uncurried == null) {
      throw InvalidDidException();
    }

    return uncurried;
  }

  static UncurriedDidInnerPuzzle? maybeFromProgram(Program innerPuzzle) {
    final uncurriedPuzzle = innerPuzzle.uncurry();
    return maybeFromUncurriedProgram(uncurriedPuzzle);
  }

  static Future<UncurriedDidInnerPuzzle> fromProgramAsync(
      Program innerPuzzle) async {
    final uncurried =
        maybeFromUncurriedProgram(await innerPuzzle.uncurryAsync());
    if (uncurried == null) {
      throw InvalidDidException();
    }

    return uncurried;
  }

  static UncurriedDidInnerPuzzle? maybeFromUncurriedProgram(
      ModAndArguments uncurriedPuzzle) {
    if (uncurriedPuzzle.mod != didInnerPuzzleProgram) {
      return null;
    }
    final arguments = uncurriedPuzzle.arguments;

    return UncurriedDidInnerPuzzle._(
      p2Puzzle: arguments[0],
      backUpIdsHashProgram: arguments[1],
      numberOfVerificationsRequiredProgram: arguments[2],
      singletonStructureProgram: arguments[3],
      metadataProgram: arguments[4],
    );
  }

  final Program p2Puzzle;
  final Program backUpIdsHashProgram;
  final Program numberOfVerificationsRequiredProgram;
  final Program singletonStructureProgram;
  final Program metadataProgram;

  int get nVerificationsRequired =>
      numberOfVerificationsRequiredProgram.toInt();
  Puzzlehash get backUpIdsHash => Puzzlehash(backUpIdsHashProgram.atom);
  DidMetadata get metadata => DidMetadata.fromProgram(metadataProgram);
}
