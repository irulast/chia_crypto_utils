// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/exceptions/bad_coin_id_exception.dart';
import 'package:chia_utils/src/api/exceptions/bad_request_exception.dart';
import 'package:chia_utils/src/api/exceptions/double_spend_exception.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/core/models/blockchain_state.dart';

class ChiaFullNodeInterface {
  const ChiaFullNodeInterface(this.fullNode);

  final FullNode fullNode;

  Future<List<Coin>> getCoinsByPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final recordsResponse = await fullNode.getCoinRecordsByPuzzleHashes(
      puzzlehashes,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
    mapResponseToError(recordsResponse);

    return recordsResponse.coinRecords.map((record) => record.toCoin()).toList();
  }

  Future<int> getBalance(List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
  }) async {
    final coins = await getCoinsByPuzzleHashes(puzzlehashes, startHeight: startHeight, endHeight: endHeight);
    final balance = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    return balance;
  }

  Future<void> pushTransaction(SpendBundle spendBundle) async {
     final response = await fullNode.pushTransaction(spendBundle);
     mapResponseToError(response);
  }

  Future<Coin?> getCoinById(Puzzlehash coinId) async {
    final coinRecordResponse = await fullNode.getCoinByName(coinId);
    mapResponseToError(coinRecordResponse);

    return coinRecordResponse.coinRecord?.toCoin();
  }

  Future<CoinSpend?> getCoinSpend(Coin coin) async {
    final coinSpendResponse = await fullNode.getPuzzleAndSolution(coin.id, coin.spentBlockIndex);
    mapResponseToError(coinSpendResponse);

    return coinSpendResponse.coinSpend;
  }

  Future<List<CatCoin>> getCatCoinsByOuterPuzzleHashes(List<Puzzlehash> puzzlehashes) async {
    final coins = await getCoinsByPuzzleHashes(puzzlehashes);
    final catCoins = <CatCoin>[];
    for(final coin in coins) {
      final parentCoin = await getCoinById(coin.parentCoinInfo);

      final parentCoinSpend = await getCoinSpend(parentCoin!);
      
      catCoins.add(
        CatCoin(
          parentCoinSpend: parentCoinSpend!, 
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

  Future<BlockchainState> getBlockchainState() async {
    final blockchainStateResponse = await fullNode.getBlockchainState();
    mapResponseToError(blockchainStateResponse);

    return blockchainStateResponse.blockchainState!;
  }

  static void mapResponseToError(ChiaBaseResponse baseResponse) {
    if(baseResponse.success) {
      return;
    }
    final errorMessage = baseResponse.error!;

    // no error on resource not found
    if (errorMessage.contains('not found')) {
      return;
    }

    if (errorMessage.contains('DOUBLE_SPEND')) {
      throw DoubleSpendException();
    }

    if (errorMessage.contains('bad bytes32 initializer')) {
      throw BadCoinIdException();
    }

    throw BadRequestException(message: errorMessage);
  }
}
