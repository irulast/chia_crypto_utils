// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/cat/exceptions/invalid_cat_exception.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';

// ignore: must_be_immutable
class CatCoin extends Coin {
  CoinSpend parentCoinSpend;
  late Puzzlehash assetId;
  bool isEveCoin;

  CatCoin({
    required this.parentCoinSpend,
    required int confirmedBlockIndex,
    required int spentBlockIndex,
    required bool coinbase,
    required int timestamp,
    required Bytes parentCoinInfo,
    required Puzzlehash puzzlehash,
    required int amount,
    Puzzlehash? assetId,
    this.isEveCoin = false,
  }) : super(
      confirmedBlockIndex: confirmedBlockIndex,
      spentBlockIndex: spentBlockIndex,
      coinbase: coinbase,
      timestamp: timestamp,
      parentCoinInfo: parentCoinInfo,
      puzzlehash: puzzlehash,
      amount: amount,
    ) {
      if(isEveCoin) {
        this.assetId = assetId!;
      } else {
        final uncurriedParentPuzzleReveal = parentCoinSpend.puzzleReveal.uncurry();
        if(uncurriedParentPuzzleReveal.program.toSource() != catProgram.toSource()) {
            throw InvalidCatException();
        }
        // second argument to the cat puzzle is the asset id
        assetId = Puzzlehash(uncurriedParentPuzzleReveal.arguments[1].atom);
      }
    }
  
  factory CatCoin.fromCoin(Coin coin, CoinSpend parentCoinSpend, {bool isEveCoin = false, Puzzlehash? assetId}) {
    return CatCoin(
      parentCoinSpend: parentCoinSpend, 
      confirmedBlockIndex: coin.confirmedBlockIndex, 
      spentBlockIndex: coin.spentBlockIndex, 
      coinbase: coin.coinbase, 
      timestamp: coin.timestamp, 
      parentCoinInfo: coin.parentCoinInfo, 
      puzzlehash: coin.puzzlehash, 
      amount: coin.amount,
      isEveCoin: isEveCoin,
      assetId: assetId,
    );
  }
  
  Program get lineageProof {
    if (!isEveCoin) {
      return Program.list([
        Program.fromBytes(parentCoinSpend.coin.parentCoinInfo.toUint8List()),
        // third argument to the cat puzzle is the inner puzzle
        Program.fromBytes(parentCoinSpend.puzzleReveal.uncurry().arguments[2].hash()),
        Program.fromInt(parentCoinSpend.coin.amount)
      ]);
    }
    return Program.nil;

  }
}
