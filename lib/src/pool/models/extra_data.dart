import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/pool/models/pool_state.dart';

class PlotNftExtraData {
  PlotNftExtraData(this.poolState, this.delayTime, this.delayPuzzlehash);

  factory PlotNftExtraData.fromProgram(Program extraDataProgram) {
    final poolState = PoolState.fromExtraDataProgram(extraDataProgram);

    final extraDataProgramList = extraDataProgram.toList();

    final delayTime = extraDataProgramList
        .singleWhere((p) => String.fromCharCode(p.first().toInt()) == delayTimeIdentifier)
        .rest()
        .toInt();
    final delayPuzzlehash = Puzzlehash(
      extraDataProgramList
          .singleWhere((p) => String.fromCharCode(p.first().toInt()) == delayPuzzlehashIdentifier)
          .rest()
          .atom,
    );

    return PlotNftExtraData(poolState, delayTime, delayPuzzlehash);
  }

  static const poolStateIdentifier = 'p';
  static const delayTimeIdentifier = 't';
  static const delayPuzzlehashIdentifier = 'h';

  final PoolState poolState;
  final int delayTime;
  final Puzzlehash delayPuzzlehash;

  Program toProgram() => Program.list([
        Program.cons(
            Program.fromString(poolStateIdentifier), Program.fromBytes(poolState.toBytesChia())),
        Program.cons(Program.fromString(delayTimeIdentifier), Program.fromInt(delayTime)),
        Program.cons(
            Program.fromString(delayPuzzlehashIdentifier), Program.fromBytes(delayPuzzlehash)),
      ]);
}
