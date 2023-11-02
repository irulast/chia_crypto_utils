// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:equatable/equatable.dart';

class CoinSpend extends Equatable with ToBytesMixin, ToJsonMixin {
  const CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });
  factory CoinSpend.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return CoinSpend.fromStream(iterator);
  }
  factory CoinSpend.fromStream(Iterator<int> iterator) {
    final coin = CoinPrototype.fromStream(iterator);
    final puzzleReveal = Program.fromStream(iterator);
    final solution = Program.fromStream(iterator);
    return CoinSpend(
      coin: coin,
      puzzleReveal: puzzleReveal,
      solution: solution,
    );
  }

  factory CoinSpend.fromJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>),
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String),
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }

  factory CoinSpend.fromCamelJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromCamelJson(json['coin'] as Map<String, dynamic>),
      puzzleReveal: Program.deserializeHex(json['puzzleReveal'] as String),
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }

  factory CoinSpend.fromGeneratorCoinProgram(Program coinProgram) {
    final programList = coinProgram.toList();

    final parentCoinInfo = programList[0].atom;

    final puzzle = programList[1];

    final amount = programList[2].toInt();

    final solution = programList[3];

    final puzzlehash = puzzle.hash();

    return CoinSpend(
      coin: CoinPrototype(
        parentCoinInfo: parentCoinInfo,
        puzzlehash: puzzlehash,
        amount: amount,
      ),
      puzzleReveal: puzzle,
      solution: solution,
    );
  }

  final CoinPrototype coin;
  final Program puzzleReveal;
  final Program solution;

  Program get outputProgram => puzzleReveal.run(solution).program;

  Future<Program> get outputProgramAsync async {
    return puzzleReveal.runAsync(solution).then((value) => value.program);
  }

  List<Condition> get conditions {
    return BaseWalletService.extractConditionsFromResult(
      outputProgram,
      (_) => true,
      GeneralCondition.new,
    );
  }

  List<CoinPrototype> get additions {
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions
        .map(
          (ccc) => CoinPrototype(
            parentCoinInfo: coin.id,
            puzzlehash: ccc.destinationPuzzlehash,
            amount: ccc.amount,
          ),
        )
        .toList();
  }

  int get fee {
    final reserveFeeConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      ReserveFeeCondition.isThisCondition,
      ReserveFeeCondition.fromProgram,
    );
    return reserveFeeConditions.fold(
      0,
      (previousValue, element) => previousValue + element.feeAmount,
    );
  }

  Future<List<CoinPrototype>> get additionsAsync async {
    final outputProgram = await outputProgramAsync;
    return _getAdditionsFromOutputProgram(outputProgram);
  }

  List<CoinPrototype> _getAdditionsFromOutputProgram(Program outputProgram) {
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions
        .map(
          (ccc) => CoinPrototype(
            parentCoinInfo: coin.id,
            puzzlehash: ccc.destinationPuzzlehash,
            amount: ccc.amount,
          ),
        )
        .toList();
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin': coin.toJson(),
        'puzzle_reveal': puzzleReveal.toBytes().toHexWithPrefix(),
        'solution': solution.toBytes().toHexWithPrefix(),
      };

  Map<String, dynamic> toCamelJson() => <String, dynamic>{
        'coin': coin.toCamelJson(),
        'puzzleReveal': puzzleReveal.toBytes().toHexWithPrefix(),
        'solution': solution.toBytes().toHexWithPrefix(),
      };

  @override
  Bytes toBytes() {
    return coin.toBytes() +
        Bytes(puzzleReveal.toBytes()) +
        Bytes(solution.toBytes());
  }

  SpendType? get type {
    return PuzzleDriver.match(puzzleReveal)?.type;
  }

  // TODO(nvjoshi2): make async the default
  List<Payment> get payments => _getPaymentsFromOutputProgram(outputProgram);

  Future<List<Payment>> get paymentsAsync async {
    return _getPaymentsFromOutputProgram(await outputProgramAsync);
  }

  List<Memo> get memosSync => payments.memos;

  Future<List<Memo>> get memos async {
    final payments = await paymentsAsync;
    return payments.memos;
  }

  Future<List<String>> get memoStrings async {
    final payments = await paymentsAsync;
    final memoStrings = payments.fold(
      <String>[],
      (List<String> previousValue, payment) =>
          previousValue + payment.memoStrings,
    );
    return memoStrings;
  }

  List<Payment> _getPaymentsFromOutputProgram(Program outputProgram) {
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      outputProgram,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions.map((e) => e.toPayment()).toList();
  }

  Future<PaymentsAndAdditions> get paymentsAndAdditionsAsync async {
    final outputProgram = await outputProgramAsync;
    final additions = _getAdditionsFromOutputProgram(outputProgram);
    final payments = _getPaymentsFromOutputProgram(outputProgram);
    return PaymentsAndAdditions(payments, additions);
  }

  @override
  String toString() =>
      'CoinSpend(coin: $coin, puzzleReveal: $puzzleReveal, solution: $solution)';

  @override
  List<Object?> get props => [coin, puzzleReveal, solution];
}

enum SpendType { standard, cat, cat1, nft, did }

class PaymentsAndAdditions {
  PaymentsAndAdditions(this.payments, this.additions);
  final List<Payment> payments;
  final List<CoinPrototype> additions;
}
