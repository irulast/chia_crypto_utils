import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PlotNftExtraData with ToBytesMixin {
  PlotNftExtraData(this.poolState, this.delayTime, this.delayPuzzlehash);

  factory PlotNftExtraData.fromProgram(Program extraDataProgram) {
    final poolState = PoolState.fromExtraDataProgram(extraDataProgram);

    final extraDataProgramList = extraDataProgram.toList();

    final delayTime = extraDataProgramList
        .singleWhere(
          (p) => String.fromCharCode(p.first().toInt()) == delayTimeIdentifier,
        )
        .rest()
        .toInt();
    final delayPuzzlehash = Puzzlehash(
      extraDataProgramList
          .singleWhere(
            (p) =>
                String.fromCharCode(p.first().toInt()) ==
                delayPuzzlehashIdentifier,
          )
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
    return poolState.toBytes() + intTo32Bytes(delayTime) + delayPuzzlehash;
  }

  factory PlotNftExtraData.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return PlotNftExtraData.fromStream(iterator);
  }

  factory PlotNftExtraData.fromStream(Iterator<int> iterator) {
    final poolState = PoolState.fromStream(iterator);
    final delayTime =
        bytesToInt(iterator.extractBytesAndAdvance(4), Endian.big);
    final delayPuzzlehash = Puzzlehash.fromStream(iterator);

    return PlotNftExtraData(poolState, delayTime, delayPuzzlehash);
  }
}
