import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/did/models/did_metadata.dart';

class UncurriedDidInnerPuzzle {
  UncurriedDidInnerPuzzle._({
    required this.p2Puzzle,
    required this.backUpIdsHashProgram,
    required this.numberOfVerificationsRequiredProgram,
    required this.singletonStructureProgram,
    required this.metadataProgram,
  });

  factory UncurriedDidInnerPuzzle.fromProgram(Program innerPuzzle) {
    final uncurried = _fromUncurriedFullPuzzle(innerPuzzle.uncurry());
    if (uncurried == null) {
      throw InvalidDIDException();
    }

    return uncurried;
  }

  static UncurriedDidInnerPuzzle? _fromUncurriedFullPuzzle(ModAndArguments uncurriedPuzzle) {
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

  int get nVerificationsRequired => numberOfVerificationsRequiredProgram.toInt();
  Puzzlehash get backUpIdsHash => Puzzlehash(backUpIdsHashProgram.atom);
  DidMetadata get metadata => DidMetadata.fromProgram(metadataProgram);
}
