import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';

import 'condition.dart';

class AssertCoinAnnouncementCondition implements Condition {
  static int conditionCode = 61;

  Puzzlehash coinId;
  Puzzlehash message;

  Puzzlehash get announcementId {
    return (coinId + message).sha256Hash();
  }

  AssertCoinAnnouncementCondition(this.coinId, this.message);

  @override
  Program get program {
    return Program.list([
      Program.fromInt(conditionCode),
      Program.fromBytes(announcementId.bytes),
    ]);
  }
}