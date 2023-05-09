import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class LineageProof with ToBytesMixin, ToProgramMixin {
  const LineageProof({
    required this.parentCoinInfo,
    required this.innerPuzzlehash,
    required this.amount,
  });

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

  final Bytes? parentCoinInfo;
  final Puzzlehash? innerPuzzlehash;
  final int? amount;

  @override
  Program toProgram() => Program.list([
        if (parentCoinInfo != null) Program.fromBytes(parentCoinInfo!),
        if (innerPuzzlehash != null) Program.fromBytes(innerPuzzlehash!),
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
}
