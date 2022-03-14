import 'package:chia_utils/chia_crypto_utils.dart';

class CatCoin extends Coin {
  CoinSpend parentCoinSpend;
  Puzzlehash assetId;

  CatCoin({
    required this.parentCoinSpend,
    required this.assetId,
    required int confirmedBlockIndex,
    required int spentBlockIndex,
    required bool coinbase,
    required int timestamp,
    required Puzzlehash parentCoinInfo,
    required Puzzlehash puzzlehash,
    required int amount,
  }) : super(
      confirmedBlockIndex: confirmedBlockIndex,
      spentBlockIndex: spentBlockIndex,
      coinbase: coinbase,
      timestamp: timestamp,
      parentCoinInfo: parentCoinInfo,
      puzzlehash: puzzlehash,
      amount: amount,
    );
  
  Program get lineageProof {
    return Program.list([
      Program.fromBytes(parentCoinSpend.coin.parentCoinInfo.bytes),
      Program.fromBytes(parentCoinSpend.puzzleReveal.uncurry().arguments[2].hash()),
      Program.fromInt(parentCoinSpend.coin.amount)
   ]);
  }
}
