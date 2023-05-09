import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CatPayment extends Payment {
  CatPayment(super.amount, super.puzzlehash, {List<Bytes> memos = const []})
      : super(
          memos: <Bytes>[puzzlehash, ...memos],
        );

  CatPayment.withStringMemos(super.amount, super.puzzlehash, {List<String> memos = const []})
      : super(memos: <Bytes>[puzzlehash, ...memos.map(Bytes.encodeFromString)]);
  CatPayment.withIntMemos(super.amount, super.puzzlehash, {List<int> memos = const []})
      : super(
          memos: <Bytes>[
            puzzlehash,
            ...memos.map(
              (e) => Bytes.encodeFromString(e.toString()),
            )
          ],
        );
}
