import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:hex/hex.dart';

class CoinSpend {
  CoinPrototype coin;
  Program puzzleReveal;
  Program solution;

  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
      'coin': coin.toJson(),
      'puzzle_reveal': const HexEncoder().convert(puzzleReveal.serialize()),
      'solution': const HexEncoder().convert(solution.serialize())
    };

  factory CoinSpend.fromJson(Map<String, dynamic> json) {
    return CoinSpend(
      coin: CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>) ,
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String) ,
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }
}
