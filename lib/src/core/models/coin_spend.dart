import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/models/coin.dart';
import 'package:hex/hex.dart';

class CoinSpend {
  Coin coin;
  Program puzzleReveal;
  Program solution;

  CoinSpend({
    required this.coin,
    required this.puzzleReveal,
    required this.solution,
  });

  CoinSpend.fromJson(Map<String, dynamic> json)
    : coin = Coin.fromJson(json['coin']),
      puzzleReveal = Program.fromHex(json['puzzle_reveal']),
      solution = Program.fromHex(json['solution']);

  Map<String, dynamic> toJson() => {
      'coin': coin.toJson(),
      'puzzle_reveal': const HexEncoder()
        .convert(puzzleReveal.serialize()),
      'solution': const HexEncoder().convert(solution.serialize())
  };
}