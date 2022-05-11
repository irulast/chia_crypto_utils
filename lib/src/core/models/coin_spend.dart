// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';
import 'package:chia_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';
import 'package:chia_utils/src/utils/serialization.dart';
import 'package:hex/hex.dart';

class CoinSpend with ToBytesMixin, ToBytesChiaMixin {
  CoinPrototype coin;
  Program puzzleReveal;
  Program solution;

  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

  List<CoinPrototype> get additions {
    final result = puzzleReveal.run(solution).program;
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
        result, CreateCoinCondition.isThisCondition, CreateCoinCondition.fromProgram,);

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
    var length = decodeInt(bytes.sublist(0, 4));
    var left = 4;
    var right = left + length;

    final coin = CoinPrototype.fromBytes(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final puzzleReveal = Program.deserialize(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final solution = Program.deserialize(bytes.sublist(left, right));

    return CoinSpend(coin: coin, puzzleReveal: puzzleReveal, solution: solution);
  }

  @override
  Bytes toBytesChia() {
    return coin.toBytesChia() + 
      Bytes(puzzleReveal.serialize()) + 
      Bytes(solution.serialize());
  }

  factory CoinSpend.fromStreamChia(Iterator<int> iterator){
    final coin = CoinPrototype.fromStreamChia(iterator);
    final puzzleReveal = Program.fromStreamChia(iterator);
    final solution = Program.fromStreamChia(iterator);
    return CoinSpend(coin: coin, puzzleReveal: puzzleReveal, solution: solution);
  }

  @override
  Bytes toBytes() {
    return serializeList(<dynamic>[coin, puzzleReveal, solution]);
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

  @override
  String toString() => 'CoinSpend(coin: $coin, puzzleReveal: $puzzleReveal, solution: $solution)';
}

enum SpendType { standard, cat, nft }
