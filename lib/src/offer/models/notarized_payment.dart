import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NotarizedPayment implements Payment {
  NotarizedPayment.fromPayment(this.payment, this.nonce);

  NotarizedPayment.withDefaultNonce(
    int amount,
    Puzzlehash puzzlehash,
  )   : payment = Payment.withRawMemos(
          amount,
          puzzlehash,
          [Memo(puzzlehash.byteList)],
        ),
        nonce = Puzzlehash.zeros();
  final Payment payment;
  final Bytes nonce;

  @override
  int get amount => payment.amount;
  @override
  Puzzlehash get puzzlehash => payment.puzzlehash;
  @override
  List<Memo>? get memos => payment.memos;

  @override
  Program toProgram() => payment.toProgram();

  @override
  String toString() {
    return 'NotarizedPayment(amount: ${payment.amount}, puzzlehash: ${payment.puzzlehash}, nonce: $nonce, memos: ${payment.memos})';
  }

  @override
  List<String> get memoStrings => payment.memoStrings;

  @override
  CreateCoinCondition toCreateCoinCondition() =>
      payment.toCreateCoinCondition();

  @override
  NotarizedPayment toNotarizedPayment(Bytes nonce) => this;
}
