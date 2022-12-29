import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class LineageProof with ToBytesMixin {
  const LineageProof({
    required this.parentCoinInfo,
    required this.innerPuzzlehash,
    required this.amount,
  });

  final Bytes? parentCoinInfo;
  final Puzzlehash? innerPuzzlehash;
  final int? amount;

  Program toProgram() => Program.list([
        if (parentCoinInfo != null) Program.fromBytes(parentCoinInfo!),
        if (innerPuzzlehash != null) Program.fromBytes(innerPuzzlehash!),
        if (amount != null) Program.fromInt(amount!),
      ]);

  factory LineageProof.fromStream(Iterator<int> iterator) {
    final parentCoinInfoBytes = iterator.extractBytesAndAdvance(Puzzlehash.bytesLength);
    final parentCoinInfo = Bytes(parentCoinInfoBytes);

    final innerPuzzlehashBytes = iterator.extractBytesAndAdvance(Puzzlehash.bytesLength);
    final innerPuzzlehash = Puzzlehash(innerPuzzlehashBytes);

    // coin amount is encoded with 64 bits
    final amountBytes = iterator.extractBytesAndAdvance(8);
    final amount = bytesToInt(amountBytes, Endian.big);

    return LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: innerPuzzlehash,
      amount: amount,
    );
  }

  @override
  Bytes toBytes() {
    var bytes = <int>[];
    if (parentCoinInfo != null) {
      bytes += parentCoinInfo!;
    }
    if (innerPuzzlehash != null) {
      bytes += innerPuzzlehash!;
    }
    if (amount != null) {
      bytes += Bytes(intTo64Bits(amount!));
    }

    return Bytes(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LineageProof) {
      return false;
    }
    return toProgram() == other.toProgram();
  }

  @override
  int get hashCode => toProgram().hashCode;

  @override
  String toString() =>
      'LineageProof(parentCoinInfo: $parentCoinInfo, innerPuzzlehash: $innerPuzzlehash, amount: $amount)';
}
