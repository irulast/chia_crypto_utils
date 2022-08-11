import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/plot_nft/models/exceptions/invalid_plot_nft_exception.dart';

class PlotNftExtraData with ToBytesMixin {
  PlotNftExtraData(this.poolState, this.delayTime, this.delayPuzzlehash);

  factory PlotNftExtraData.fromProgram(Program extraDataProgram) {
    final poolState = PoolState.fromExtraDataProgram(extraDataProgram);

    final extraDataProgramList = extraDataProgram.toList();

    final delayTimePrograms = extraDataProgramList.where(
      (p) => String.fromCharCode(p.first().toInt()) == delayTimeIdentifier,
    );
    if (delayTimePrograms.isEmpty || delayTimePrograms.length > 1) {
      throw InvalidPlotNftException();
    }
    final delayTime = delayTimePrograms.single.rest().toInt();

    final extraDataPrograms = extraDataProgramList.where(
      (p) => String.fromCharCode(p.first().toInt()) == delayPuzzlehashIdentifier,
    );
    if (extraDataPrograms.isEmpty || extraDataPrograms.length > 1) {
      throw InvalidPlotNftException();
    }
    final delayPuzzlehash = Puzzlehash(
      extraDataPrograms.single.rest().atom,
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
          Program.fromString(poolStateIdentifier),
          Program.fromBytes(poolState.toBytes()),
        ),
        Program.cons(
          Program.fromString(delayTimeIdentifier),
          Program.fromInt(delayTime),
        ),
        Program.cons(
          Program.fromString(delayPuzzlehashIdentifier),
          Program.fromBytes(delayPuzzlehash),
        ),
      ]);

  @override
  Bytes toBytes() {
    return poolState.toBytes() + intTo32Bits(delayTime) + delayPuzzlehash;
  }

  factory PlotNftExtraData.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return PlotNftExtraData.fromStream(iterator);
  }

  factory PlotNftExtraData.fromStream(Iterator<int> iterator) {
    final poolState = PoolState.fromStream(iterator);
    final delayTime = bytesToInt(iterator.extractBytesAndAdvance(4), Endian.big);
    final delayPuzzlehash = Puzzlehash.fromStream(iterator);

    return PlotNftExtraData(poolState, delayTime, delayPuzzlehash);
  }

  @override
  String toString() =>
      'PlotNftExtraData(poolState: $poolState, delayTime: $delayTime, delayPuzzlehash: $delayPuzzlehash)';
}
