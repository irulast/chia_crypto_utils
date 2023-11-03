import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Map<Bytes, List<Memo>> makeTransactionMemos(
  SpendBundle spendBundle,
  List<Memo> memos,
) {
  return Map.fromEntries(
    spendBundle.coins.map((coin) => MapEntry(coin.id, memos)),
  );
}

extension MemosFromStrings on Iterable<String> {
  List<Memo> toMemos() {
    return map((memo) => Memo(Bytes.encodeFromString(memo))).toList();
  }
}
