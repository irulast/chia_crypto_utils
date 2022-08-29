// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/blockchain_state.dart';
import 'package:chia_crypto_utils/src/plot_nft/models/exceptions/invalid_pool_singleton_exception.dart';

class ChiaFullNodeInterface {
  const ChiaFullNodeInterface(this.fullNode);
  factory ChiaFullNodeInterface.fromURL(
    String baseURL, {
    Bytes? certBytes,
    Bytes? keyBytes,
  }) {
    return ChiaFullNodeInterface(
      FullNodeHttpRpc(
        baseURL,
        certBytes: certBytes,
        keyBytes: keyBytes,
      ),
    );
  }

  ChiaFullNodeInterface.fromContext() : fullNode = FullNodeHttpRpc.fromContext();

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
    final balance = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    return balance;
  }

  Future<ChiaBaseResponse> pushTransaction(SpendBundle spendBundle) async {
    final response = await fullNode.pushTransaction(spendBundle);
    mapResponseToError(response);
    return response;
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

    return coinRecordsResponse.coinRecords.map((record) => record.toCoin()).toList();
  }

  Future<List<Coin>> getCoinsByParentIds(
    List<Bytes> parentIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final coinRecordsResponse = await fullNode.getCoinsByParentIds(
      parentIds,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
    mapResponseToError(coinRecordsResponse);

    return coinRecordsResponse.coinRecords.map((record) => record.toCoin()).toList();
  }

  Future<List<Coin>> getCoinsByMemo(Bytes memo) async {
    final coinRecordsResponse = await fullNode.getCoinsByHint(
      memo,
    );
    mapResponseToError(coinRecordsResponse);

    return coinRecordsResponse.coinRecords.map((record) => record.toCoin()).toList();
  }

  Future<CoinSpend?> getCoinSpend(Coin coin) async {
    final coinSpendResponse = await fullNode.getPuzzleAndSolution(coin.id, coin.spentBlockIndex);
    mapResponseToError(coinSpendResponse);

    return coinSpendResponse.coinSpend;
  }

  Future<List<CatCoin>> getCatCoinsByMemo(
    Bytes memo,
  ) async {
    final coins = await getCoinsByMemo(memo);
    return _hydrateCatCoins(coins);
  }

  Future<List<CatCoin>> getCatCoinsByOuterPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final coins = await getCoinsByPuzzleHashes(
      puzzlehashes,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
    return _hydrateCatCoins(coins);
  }

  Future<List<CatCoin>> _hydrateCatCoins(List<Coin> unHydratedCatCoins) async {
    final catCoins = <CatCoin>[];
    for (final coin in unHydratedCatCoins) {
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

  Future<List<PlotNft>> scroungeForPlotNfts(List<Puzzlehash> puzzlehashes) async {
    final allCoins = await getCoinsByPuzzleHashes(puzzlehashes, includeSpentCoins: true);

    final spentCoins = allCoins.where((c) => c.isSpent);
    final plotNfts = <PlotNft>[];
    for (final spentCoin in spentCoins) {
      final coinSpend = await getCoinSpend(spentCoin);
      for (final childCoin in coinSpend!.additions) {
        // check if coin is singleton launcher
        if (childCoin.puzzlehash == singletonLauncherProgram.hash()) {
          final launcherId = childCoin.id;
          try {
            final plotNft = await getPlotNftByLauncherId(launcherId);
            plotNfts.add(plotNft!);
          } on InvalidPoolSingletonException {
            // pass. Launcher id was not for plot nft
          }
        }
      }
    }
    return plotNfts;
  }

  Future<PlotNft?> getPlotNftByLauncherId(Bytes launcherId) async {
    final launcherCoin = await getCoinById(launcherId);
    if (launcherCoin == null) {
      return null;
    }
    final launcherCoinSpend = await getCoinSpend(launcherCoin);
    final initialExtraData = PlotNftWalletService.launcherCoinSpendToExtraData(launcherCoinSpend!);

    final firstSingletonCoinPrototype =
        SingletonService.getMostRecentSingletonCoinFromCoinSpend(launcherCoinSpend);

    var lastNotNullPoolState = initialExtraData.poolState;
    var singletonCoin = await getCoinById(firstSingletonCoinPrototype.id);

    while (singletonCoin!.isSpent) {
      final lastCoinSpend = (await getCoinSpend(singletonCoin))!;
      final nextSingletonCoinPrototype =
          SingletonService.getMostRecentSingletonCoinFromCoinSpend(lastCoinSpend);
      final poolState = PlotNftWalletService.coinSpendToPoolState(lastCoinSpend);
      if (poolState != null) {
        lastNotNullPoolState = poolState;
      }

      singletonCoin = await getCoinById(nextSingletonCoinPrototype.id);
    }

    PlotNftWalletService().validateSingletonPuzzlehash(
      singletonPuzzlehash: singletonCoin.puzzlehash,
      launcherId: launcherId,
      poolState: lastNotNullPoolState,
      delayPuzzlehash: initialExtraData.delayPuzzlehash,
      delayTime: initialExtraData.delayTime,
    );

    return PlotNft(
      launcherId: launcherId,
      singletonCoin: singletonCoin,
      poolState: lastNotNullPoolState,
      delayPuzzlehash: initialExtraData.delayPuzzlehash,
      delayTime: initialExtraData.delayTime,
    );
  }

  Future<bool> checkForSpentCoins(List<CoinPrototype> coins) async {
    final ids = coins.map((c) => c.id).toList();
    final fetchedCoins = await getCoinsByIds(ids, includeSpentCoins: true);

    return fetchedCoins.any((c) => c.spentBlockIndex != 0);
  }

  Future<BlockchainState?> getBlockchainState() async {
    final blockchainStateResponse = await fullNode.getBlockchainState();
    mapResponseToError(blockchainStateResponse);

    return blockchainStateResponse.blockchainState;
  }

  Future<List<BlockRecord>> getBlockRecords(int startHeight, int endHeight) async {
    final response = await fullNode.getBlockRecords(startHeight, endHeight);
    mapResponseToError(response);

    return response.blockRecords!;
  }

  Future<AdditionsAndRemovals> getAdditionsAndRemovals(Bytes headerHash) async {
    final response = await fullNode.getAdditionsAndRemovals(headerHash);
    mapResponseToError(response);
    return AdditionsAndRemovals(additions: response.additions!, removals: response.removals!);
  }

  static void mapResponseToError(ChiaBaseResponse baseResponse) {
    if (baseResponse.success && baseResponse.error == null) {
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
