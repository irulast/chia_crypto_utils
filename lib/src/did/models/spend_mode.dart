import 'package:chia_crypto_utils/chia_crypto_utils.dart';

enum SpendMode {
  recovery(0),
  runInnerPuzzle(1);

  const SpendMode(this.code);
  factory SpendMode.fromCode(int code) {
    for (final spendMode in SpendMode.values) {
      if (spendMode.code == code) {
        return spendMode;
      }
    }
    throw InvalidDIDSpendModeCodeException(invalidCode: code);
  }

  final int code;
}
