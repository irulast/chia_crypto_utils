// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/invalid_condition_cast_exception.dart';

class NftDidMagicConditionCondition implements Condition {
  NftDidMagicConditionCondition({
    this.targetDidOwner,
    this.tradePricesList,
    this.targetDidInnerHash,
  });

  factory NftDidMagicConditionCondition.fromProgram(Program program) {
    final programList = program.toList();
    if (!isThisCondition(program)) {
      throw InvalidConditionCastException(NftDidMagicConditionCondition);
    }
    return NftDidMagicConditionCondition(
      targetDidOwner: programList[1].maybeAtom,
      tradePricesList: programList[2],
      targetDidInnerHash: Puzzlehash.maybe(programList[3].maybeAtom),
    );
  }

  static int conditionCode = -10;

  final Bytes? targetDidOwner;
  final Program? tradePricesList;
  final Puzzlehash? targetDidInnerHash;

  @override
  int get code => conditionCode;

  @override
  Program toProgram() {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromAtomOrNil(targetDidOwner),
      tradePricesList ?? Program.nil,
      Program.fromAtomOrNil(targetDidInnerHash),
    ]);
  }

  static bool isThisCondition(Program condition) {
    final conditionParts = condition.toList();
    if (conditionParts.length != 4) {
      return false;
    }
    if (conditionParts[0].toInt() != conditionCode) {
      return false;
    }
    return true;
  }

  @override
  String toString() =>
      'NftDidMagicConditionCondition(code: $targetDidOwner, announcementHash: $targetDidOwner)';
}
