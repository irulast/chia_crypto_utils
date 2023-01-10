// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';
import 'package:hex/hex.dart';

class CoinSpend with ToBytesMixin {
  CoinPrototype coin;
  Program puzzleReveal;
  Program solution;

  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

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

  @override
  Bytes toBytes() {
    return coin.toBytes() + Bytes(puzzleReveal.serialize()) + Bytes(solution.serialize());
  }

  factory CoinSpend.fromJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>),
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String),
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }

  SpendType get type {
    final uncurriedPuzzleSource = puzzleReveal.uncurry().program.toSource();
    if (uncurriedPuzzleSource == p2DelegatedPuzzleOrHiddenPuzzleProgram.toSource()) {
      return SpendType.standard;
    }
    if (uncurriedPuzzleSource == catProgram.toSource()) {
      return SpendType.cat;
    }
    throw UnimplementedError('Unimplemented spend type');
  }

  // TODO(nvjoshi2): make async the default
  List<Payment> get payments => _getPaymentsFromOutputProgram(outputProgram);

  Future<List<Payment>> get paymentsAsync async {
    return _getPaymentsFromOutputProgram(await outputProgramAsync);
  }

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

enum SpendType { standard, cat, nft }

class PaymentsAndAdditions {
  final List<Payment> payments;
  final List<CoinPrototype> additions;

  PaymentsAndAdditions(this.payments, this.additions);
}
