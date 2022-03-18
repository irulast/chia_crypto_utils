import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';

class CatSpendInfo {
  CatCoin coin;
  Program innerPuzzle;
  Program innerSolution;

  CatSpendInfo({
    required this.coin,
    required this.innerPuzzle,
    required this.innerSolution,
  });

  Program get standardCoinProgram {
    return Program.list([
      Program.fromBytes(coin.parentCoinInfo.bytes),
      Program.fromBytes(innerPuzzle.hash()),
      Program.fromInt(coin.amount),
    ]);
  }
}
