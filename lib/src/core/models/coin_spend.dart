// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';
import 'package:hex/hex.dart';

class CoinSpend with ToBytesMixin {
  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

  factory CoinSpend.fromJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>),
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String),
      solution: Program.deserializeHex(json['solution'] as String),
    );
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

  factory CoinSpend.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return CoinSpend.fromStream(iterator);
  }
  CoinPrototype coin;
  Program puzzleReveal;
  Program solution;

  Program get outputProgram => puzzleReveal.run(solution).program;

  Future<Program> get outputProgramAsync async {
    return puzzleReveal.runAsync(solution).then((value) => value.program);
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin': coin.toJson(),
        'puzzle_reveal': const HexEncoder().convert(puzzleReveal.serialize()),
        'solution': const HexEncoder().convert(solution.serialize())
      };

  @override
  Bytes toBytes() {
    return coin.toBytes() + Bytes(puzzleReveal.serialize()) + Bytes(solution.serialize());
  }

  SpendType? get type {
    final uncurriedPuzzleSource = puzzleReveal.uncurry().mod.toSource();
    if (uncurriedPuzzleSource == p2DelegatedPuzzleOrHiddenPuzzleProgram.toSource()) {
      return SpendType.standard;
    }
    if (uncurriedPuzzleSource == cat1Program.toSource()) {
      return SpendType.cat1;
    }

    if (uncurriedPuzzleSource == cat2Program.toSource()) {
      return SpendType.cat;
    }

    return null;
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
      (List<String> previousValue, payment) => previousValue + payment.memoStrings,
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
  String toString() => 'CoinSpend(coin: $coin, puzzleReveal: $puzzleReveal, solution: $solution)';
}

enum SpendType { standard, cat, cat1 }

class PaymentsAndAdditions {
  PaymentsAndAdditions(this.payments, this.additions);
  final List<Payment> payments;
  final List<CoinPrototype> additions;
}
