import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class LineageProof with ToBytesMixin, ToProgramMixin {
  const LineageProof({
    required this.parentCoinInfo,
    required this.innerPuzzlehash,
    required this.amount,
  });
  factory LineageProof.fromJson(Map<String, dynamic> json) {
    return LineageProof(
      parentCoinInfo:
          pick(json, 'parent_name').letStringOrNull(Puzzlehash.fromHex),
      innerPuzzlehash:
          pick(json, 'inner_puzzle_hash').letStringOrNull(Puzzlehash.fromHex),
      amount: pick(json, 'amount').asIntOrNull(),
    );
  }

  factory LineageProof.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final parentCoinInfo = Puzzlehash.maybeFromStream(iterator);
    final innerPuzzlehash = Puzzlehash.maybeFromStream(iterator);

    final amount = maybeIntFrom64BitsStream(iterator);

    return LineageProof(
      parentCoinInfo: parentCoinInfo,
      innerPuzzlehash: innerPuzzlehash,
      amount: amount,
    );
  }

  factory LineageProof.fromStream(Iterator<int> iterator) {
    final parentCoinInfoBytes =
        iterator.extractBytesAndAdvance(Puzzlehash.bytesLength);
    final parentCoinInfo = Bytes(parentCoinInfoBytes);

    final innerPuzzlehashBytes =
        iterator.extractBytesAndAdvance(Puzzlehash.bytesLength);
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

  final Bytes? parentCoinInfo;
  final Puzzlehash? innerPuzzlehash;
  final int? amount;

  @override
  Program toProgram() => Program.list([
        if (parentCoinInfo != null) Program.fromAtom(parentCoinInfo!),
        if (innerPuzzlehash != null) Program.fromAtom(innerPuzzlehash!),
        if (amount != null) Program.fromInt(amount!),
      ]);

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
  Bytes toBytes() {
    return Bytes([
      ...parentCoinInfo.optionallySerialize(),
      ...innerPuzzlehash.optionallySerialize(),
      ...optionallySerializeInt(amount),
    ]);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'parent_name': parentCoinInfo?.toHex(),
      'inner_puzzle_hash': innerPuzzlehash?.toHex(),
      'amount': amount,
    };
  }
}
