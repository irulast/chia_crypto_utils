// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';

class CatTransport {
  FullNode fullNode;

  CatTransport(this.fullNode);

  Future<List<CatCoin>> getCatCoinsByOuterPuzzleHashes(List<Puzzlehash> puzzlehashes, Puzzlehash assetId) async {
    final coins = await fullNode.getCoinRecordsByPuzzleHashes(puzzlehashes);
    final catCoins = <CatCoin>[];
    for(final coin in coins) {
      final parentCoin = await fullNode.getCoinByName(coin.parentCoinInfo);

      final parentCoinSpend = await fullNode.getPuzzleAndSolution(parentCoin.id, parentCoin.spentBlockIndex);
      
      catCoins.add(
        CatCoin(
          parentCoinSpend: parentCoinSpend, 
          confirmedBlockIndex: coin.confirmedBlockIndex, 
          spentBlockIndex: coin.spentBlockIndex, 
          coinbase: coin.coinbase, 
          timestamp: coin.timestamp,
          parentCoinInfo: coin.parentCoinInfo, 
          puzzlehash: coin.puzzlehash, 
          amount: coin.amount,
        ),
      );
    }
    
    return catCoins;
  }
}
