import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CatSolution with ToProgramMixin {
  factory CatSolution.fromProgram(Program program) {
    final programList = program.toList();
    final innerPuzzleSolution = programList[0];

    final lineageProof = programList[1];

    final previousCoinId = programList[2].atom;
    final thisCoinInfo = CoinPrototype.fromProgram(programList[3]);

    final nextCoinProof = CoinPrototype.fromProgram(programList[4]);

    final previousSubtotal = programList[5].toInt();
    final extraDelta = programList[6].toInt();

    return CatSolution._(
      program: program,
      innerPuzzleSolution: innerPuzzleSolution,
      lineageProof: lineageProof,
      previousCoinId: previousCoinId,
      thisCoinInfo: thisCoinInfo,
      nextCoinProof: nextCoinProof,
      previousSubtotal: previousSubtotal,
      extraDelta: extraDelta,
    );
  }
  CatSolution._({
    required Program program,
    required this.innerPuzzleSolution,
    required this.lineageProof,
    required this.previousCoinId,
    required this.thisCoinInfo,
    required this.nextCoinProof,
    required this.previousSubtotal,
    required this.extraDelta,
  }) : _program = program;
  static CatSolution? maybeFromProgram(Program program) {
    try {
      return CatSolution.fromProgram(program);
    } catch (e) {
      LoggingContext()
          .error('Error parsing cat solution from program: $program');
      return null;
    }
  }

  final Program _program;

  final Program innerPuzzleSolution;
  final Program lineageProof;

  final Bytes previousCoinId;

  final CoinPrototype thisCoinInfo;

  /// puzzle hash is p2 puzzlehash
  final CoinPrototype nextCoinProof;

  final int previousSubtotal;

  final int extraDelta;

  @override
  Program toProgram() {
    return _program;
  }

  CoinPrototype getChild(Puzzlehash assetId) {
    return CoinPrototype(
      parentCoinInfo: nextCoinProof.parentCoinInfo,
      puzzlehash:
          WalletKeychain.makeOuterPuzzleHash(nextCoinProof.puzzlehash, assetId),
      amount: nextCoinProof.amount,
    );
  }
}
