// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/blockchain_state.dart';

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

    return recordsResponse.coinRecords
        .map((record) => record.toCoin())
        .toList();
  }

  Future<int> getBalance(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
  }) async {
    final coins = await getCoinsByPuzzleHashes(
      puzzlehashes,
      startHeight: startHeight,
      endHeight: endHeight,
    );
    final balance =
        coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    return balance;
  }

  Future<void> pushTransaction(SpendBundle spendBundle) async {
    final response = await fullNode.pushTransaction(spendBundle);
    mapResponseToError(response);
  }

  Future<Coin?> getCoinById(Bytes coinId) async {
    final coinRecordResponse = await fullNode.getCoinByName(coinId);
    mapResponseToError(coinRecordResponse);

    return coinRecordResponse.coinRecord?.toCoin();
  }

  Future<List<Coin>> getCoinsByIds(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final coinRecordsResponse = await fullNode.getCoinsByNames(
      coinIds,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
    mapResponseToError(coinRecordsResponse);

    return coinRecordsResponse.coinRecords
        .map((record) => record.toCoin())
        .toList();
  }

  Future<CoinSpend?> getCoinSpend(Coin coin) async {
    final coinSpendResponse =
        await fullNode.getPuzzleAndSolution(coin.id, coin.spentBlockIndex);
    mapResponseToError(coinSpendResponse);

    return coinSpendResponse.coinSpend;
  }

  Future<List<CatCoin>> getCatCoinsByOuterPuzzleHashes(
    List<Puzzlehash> puzzlehashes,
  ) async {
    final coins = await getCoinsByPuzzleHashes(puzzlehashes);
    final catCoins = <CatCoin>[];
    for (final coin in coins) {
      final parentCoin = await getCoinById(coin.parentCoinInfo);

      final parentCoinSpend = await getCoinSpend(parentCoin!);

      catCoins.add(
        CatCoin(
          parentCoinSpend: parentCoinSpend!,
          coin: coin,
        ),
      );
    }

    return catCoins;
  }

  Future<PlotNft> getPlotNftByLauncherId(Bytes launcherId) async {
    final launcherCoin = await getCoinById(launcherId);
    final launcherCoinSpend = await getCoinSpend(launcherCoin!);
    final plotNft = PlotNft.fromCoinSpend(launcherCoinSpend!, launcherId);

    final singletonCoin = await getCoinById(plotNft.singletonCoin.id);
    if (singletonCoin!.spentBlockIndex != 0) {
      throw UnimplementedError(
        'Does not support plot entities that have been modified since creation',
      );
    }
    return plotNft;
  }

  Future<bool> checkForSpentCoins(List<CoinPrototype> coins) async {
    final ids = coins.map((c) => c.id).toList();
    final fetchedCoins = await getCoinsByIds(ids, includeSpentCoins: true);

    return fetchedCoins.any((c) => c.spentBlockIndex != 0);
  }

  Future<BlockchainState> getBlockchainState() async {
    final blockchainStateResponse = await fullNode.getBlockchainState();
    mapResponseToError(blockchainStateResponse);

    return blockchainStateResponse.blockchainState!;
  }

  static void mapResponseToError(ChiaBaseResponse baseResponse) {
    if (baseResponse.success) {
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

    if (errorMessage.contains('ASSERT_ANNOUNCE_CONSUMED_FAILED')) {
      throw AssertAnnouncementConsumeFailedException();
    }

    throw BadRequestException(message: errorMessage);
  }
}
