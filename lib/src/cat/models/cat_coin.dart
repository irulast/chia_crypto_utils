import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/exceptions/invalid_cat_exception.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';

// ignore: must_be_immutable
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
    ) {
      final uncurriedParentPuzzle = parentCoinSpend.puzzleReveal.uncurry().program;
      if(uncurriedParentPuzzle.toSource() != catProgram.toSource()) {
        print('uncurried parent coin spend puzzle reveal does not match cat program');

        final atomArguments =  parentCoinSpend.puzzleReveal.uncurry().arguments.where((arg) => arg.isAtom);
        final argumentsAsPuzzlehashes = atomArguments.map((arg) => Puzzlehash(arg.atom));
        if (!argumentsAsPuzzlehashes.contains(assetId)) {
          print('asset id is not in uncurried parent coin spend puzzle reveal arguments');
          throw InvalidCatException();
        }
      } else {
        print('is cat coin');
      }
    }
  
  factory CatCoin.fromCoin(Coin coin, CoinSpend parentCoinSpend, Puzzlehash assetId) {
    return CatCoin(
      parentCoinSpend: parentCoinSpend, 
      assetId: assetId, 
      confirmedBlockIndex: coin.confirmedBlockIndex, 
      spentBlockIndex: coin.spentBlockIndex, 
      coinbase: coin.coinbase, 
      timestamp: coin.timestamp, 
      parentCoinInfo: coin.parentCoinInfo, 
      puzzlehash: coin.puzzlehash, 
      amount: coin.amount,
    );
  }
  
  Program get lineageProof {
    return Program.list([
      Program.fromBytes(parentCoinSpend.coin.parentCoinInfo.bytes),
      Program.fromBytes(parentCoinSpend.puzzleReveal.uncurry().arguments[2].hash()),
      Program.fromInt(parentCoinSpend.coin.amount)
   ]);
  }
}
