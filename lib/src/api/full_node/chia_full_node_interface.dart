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
    try {
      mapResponseToError(response);
    } on Exception catch (e) {
      LoggingContext().error('error pushing spend bundle ${spendBundle.toJson()} \n $e');
      rethrow;
    }
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

  Future<List<Coin>> getCoinsByHint(Puzzlehash hint, {bool includeSpentCoins = false}) async {
    final coinRecordsResponse = await fullNode.getCoinsByHint(
      hint,
      includeSpentCoins: includeSpentCoins,
    );
    mapResponseToError(coinRecordsResponse);

    return coinRecordsResponse.coinRecords.map((record) => record.toCoin()).toList();
  }

  Future<List<Coin>> getCoinsByHints(
    List<Puzzlehash> hints, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final coinsByHints = <Coin>[];
    for (final hint in hints) {
      final coinsByHint = await getCoinsByHint(
        hint,
        includeSpentCoins: includeSpentCoins,
      );
      coinsByHints.addAll(coinsByHint);
    }

    return coinsByHints;
  }

  Future<DidRecord?> getDIDInfoFromHint(Puzzlehash hint, Bytes did) async {
    final coins = await getCoinsByHint(hint);
    final didInfos = await getDIDInfosFromCoins(coins);
    final matches = didInfos.where((element) => element.did == did);

    if (matches.isEmpty) return null;
    return matches.single;
  }

  Future<List<DidRecord>> getDIDInfosFromHint(Puzzlehash hint) async {
    final coins = await getCoinsByHint(hint);
    return getDIDInfosFromCoins(coins);
  }

  Future<List<DidRecord>> getDIDInfosFromCoins(List<Coin> coins) async {
    final didInfos = <DidRecord>[];
    for (final coin in coins) {
      if (coin.amount.isEven) {
        continue;
      }
      final parentSpend = await getParentSpend(coin);
      final nftRecord = DidRecord.fromParentCoinSpend(
        parentSpend!,
        coin,
      );
      if (nftRecord != null) {
        didInfos.add(nftRecord);
      }
    }

    return didInfos;
  }

  Future<CoinSpend?> getParentSpend(Coin coin) async {
    if (coin.coinbase) return null;
    final coinSpendResponse =
        await fullNode.getPuzzleAndSolution(coin.parentCoinInfo, coin.confirmedBlockIndex);
    mapResponseToError(coinSpendResponse);

    return coinSpendResponse.coinSpend;
  }

  Future<CoinSpend?> getCoinSpend(Coin coin) async {
    final coinSpendResponse = await fullNode.getPuzzleAndSolution(coin.id, coin.spentBlockIndex);
    mapResponseToError(coinSpendResponse);

    return coinSpendResponse.coinSpend;
  }

  Future<List<CatFullCoin>> getCatCoinsByHint(
    Puzzlehash hint,
  ) async {
    final coins = await getCoinsByHint(hint);
    return hydrateCatCoins(coins);
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
    return hydrateCatCoins(coins);
  }

  Future<List<CatFullCoin>> hydrateCatCoins(
    List<Coin> unHydratedCatCoins,
  ) async {
    final catCoinFutures = <Future<CatFullCoin?>>[];
    for (final coin in unHydratedCatCoins) {
      final parentCoin = await getCoinById(coin.parentCoinInfo);

      final parentCoinSpend = await getCoinSpend(parentCoin!);

      try {
        catCoinFutures.add(
          () async {
            try {
              final catCoin = await CatFullCoin.fromParentSpendAsync(
                parentCoinSpend: parentCoinSpend!,
                coin: coin,
              );

              return catCoin;
            } on InvalidCatException {
              return null;
            }
          }(),
        );
      } on InvalidCatException {
        // pass
      }
    }
    final results = await Future.wait(catCoinFutures);

    return List<CatFullCoin>.from(results.where((element) => element != null));
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

  // finds any coins that were spent to initialize an exchange by creating a 3 mojo coin to the message puzzlehash
  // with the required memos
  Future<List<Coin>> scroungeForExchangeInitializationCoins(
    List<Puzzlehash> puzzlehashes,
  ) async {
    final allCoins = await getCoinsByPuzzleHashes(puzzlehashes, includeSpentCoins: true);

    final initializationCoins = <Coin>[];
    for (final coin in allCoins) {
      if (coin.isNotSpent) continue;

      final coinSpend = await getCoinSpend(coin);

      final paymentsAndAdditions = await coinSpend!.paymentsAndAdditionsAsync;

      // if there is no 3 mojo child, which is used to cancel the offer, this is not a valid initialization coin
      if (paymentsAndAdditions.additions.where((addition) => addition.amount == 3).isEmpty) {
        continue;
      }

      final memos = paymentsAndAdditions.payments.memos;

      // memo should look like: <derivationIndex, serializedOfferFile>
      if (memos.length != 2) continue;

      try {
        final derivationIndexMemo = decodeInt(memos.first);
        if (derivationIndexMemo.toString().length != ExchangeOfferService.derivationIndexLength) {
          continue;
        }

        final serializedOfferFileMemo = memos.last.decodedString;
        final offerFile =
            await CrossChainOfferFile.fromSerializedOfferFileAsync(serializedOfferFileMemo!);
        if (offerFile.prefix != CrossChainOfferFilePrefix.ccoffer) continue;
      } catch (e) {
        continue;
      }

      initializationCoins.add(coin);
    }
    return initializationCoins;
  }

  Future<List<NotificationCoin>> scroungeForReceivedNotificationCoins(
    List<Puzzlehash> puzzlehashes,
  ) async {
    final coinsByHint = await getCoinsByHints(puzzlehashes, includeSpentCoins: true);
    final spentCoins = coinsByHint.where((c) => c.isSpent);

    final notificationCoins = <NotificationCoin>[];
    for (final spentCoin in spentCoins) {
      final coinSpend = await getCoinSpend(spentCoin);
      final programAndArgs = await coinSpend!.puzzleReveal.uncurryAsync();
      if (programAndArgs.mod == notificationProgram) {
        try {
          final parentCoin = await getCoinById(spentCoin.parentCoinInfo);
          final parentCoinSpend = await getCoinSpend(parentCoin!);
          final notificationCoin = await NotificationCoin.fromParentSpend(
            parentCoinSpend: parentCoinSpend!,
            coin: spentCoin,
          );
          notificationCoins.add(notificationCoin);
        } catch (e) {
          continue;
        }
      }
    }
    return notificationCoins;
  }

  Future<List<NotificationCoin>> scroungeForSentNotificationCoins(
    List<Puzzlehash> puzzlehashes,
  ) async {
    final allCoins = await getCoinsByPuzzleHashes(puzzlehashes, includeSpentCoins: true);

    final spentCoins = allCoins.where((c) => c.isSpent);
    final notificationCoins = <NotificationCoin>[];
    for (final spentCoin in spentCoins) {
      final parentCoinSpend = await getCoinSpend(spentCoin);
      final additions = await parentCoinSpend!.additionsAsync;

      for (final addition in additions) {
        final childCoin = await getCoinById(addition.id);
        if (childCoin!.isSpent) {
          final coinSpend = await getCoinSpend(childCoin);
          final programAndArgs = await coinSpend!.puzzleReveal.uncurryAsync();
          if (programAndArgs.mod == notificationProgram) {
            try {
              final notificationCoin = await NotificationCoin.fromParentSpend(
                parentCoinSpend: parentCoinSpend,
                coin: childCoin,
              );
              notificationCoins.add(notificationCoin);
            } catch (e) {
              continue;
            }
          }
        }
      }
    }
    return notificationCoins;
  }

  Future<NotificationCoin?> getNotificationCoinFromCoin(Coin coin) async {
    if (coin.isNotSpent) return null;

    final parentCoinSpend = await getParentSpend(coin);
    return NotificationCoin.fromParentSpend(parentCoinSpend: parentCoinSpend!, coin: coin);
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

  Future<GetBlockRecordByHeightResponse> getBlockRecordByHeight(int height) async {
    final response = await fullNode.getBlockRecordByHeight(height);
    mapResponseToError(response);

    return response;
  }

  Future<AdditionsAndRemovals> getAdditionsAndRemovals(Bytes headerHash) async {
    final response = await fullNode.getAdditionsAndRemovals(headerHash);
    mapResponseToError(response);
    return AdditionsAndRemovals(additions: response.additions!, removals: response.removals!);
  }

  Future<MempoolItemsResponse> getAllMempoolItems() async {
    final response = await fullNode.getAllMempoolItems();
    return response;
  }

  Future<List<DidRecord>> getDIDInfosByPuzzleHashes(List<Puzzlehash> puzzlehashes) async {
    final spentCoins = (await getCoinsByPuzzleHashes(puzzlehashes, includeSpentCoins: true))
        .where((coin) => coin.spentBlockIndex != 0);

    final launcherCoinPrototypes = <CoinPrototype>[];
    for (final spentCoin in spentCoins) {
      final coinSpend = await getCoinSpend(spentCoin);
      final createCoinConditions = BaseWalletService.extractConditionsFromSolution(
        coinSpend!.solution,
        CreateCoinCondition.isThisCondition,
        CreateCoinCondition.fromProgram,
      );

      for (final ccc in createCoinConditions) {
        if (ccc.destinationPuzzlehash == singletonLauncherProgram.hash()) {
          launcherCoinPrototypes.add(
            CoinPrototype(
              parentCoinInfo: coinSpend.coin.id,
              puzzlehash: ccc.destinationPuzzlehash,
              amount: ccc.amount,
            ),
          );
        }
      }
    }

    final didInfos = <DidRecord>[];
    for (final launcherCoinPrototype in launcherCoinPrototypes) {
      try {
        final didInfo = await getDIDInfoForDID(launcherCoinPrototype.id);
        if (didInfo != null) {
          didInfos.add(didInfo);
        }
      } catch (_) {
        // pass
      }
    }
    return didInfos;
  }

  Future<DidRecord?> getDIDInfoForDID(Bytes did) async {
    final originCoin = await getCoinById(did);
    final originCoinSpend = await getCoinSpend(originCoin!);

    // didPuzzlehash is first argument in origin coin spend solution
    final didPuzzlehash = Puzzlehash(originCoinSpend!.solution.toList()[0].atom);

    final eveCoinPrototype = CoinPrototype(
      parentCoinInfo: originCoin.id,
      puzzlehash: didPuzzlehash,
      amount: originCoin.amount,
    );

    final eveCoin = await getCoinById(eveCoinPrototype.id);

    final eveCoinSpend = await getCoinSpend(eveCoin!);

    final originalDidCoinPrototype = CoinPrototype(
      parentCoinInfo: eveCoin.id,
      puzzlehash: didPuzzlehash,
      amount: eveCoin.amount,
    );

    var didCoin = await getCoinById(originalDidCoinPrototype.id);
    var didCoinParentSpend = eveCoinSpend;

    // find latest did coin
    while (didCoin!.isSpent) {
      didCoinParentSpend = await getCoinSpend(didCoin);
      final nextSingletonCoinPrototype =
          SingletonService.getMostRecentSingletonCoinFromCoinSpend(didCoinParentSpend!);

      didCoin = await getCoinById(nextSingletonCoinPrototype.id);
    }

    if (didCoinParentSpend == null) return null;
    return DidRecord.fromParentCoinSpend(didCoinParentSpend, didCoin);
  }

  static void mapResponseToError(
    ChiaBaseResponse baseResponse, {
    List<String> passStrings = const [],
  }) {
    if (baseResponse.success && baseResponse.error == null) {
      return;
    }
    final errorMessage = baseResponse.error!;

    // no error on resource not found
    if (errorMessage.contains('not found') || passStrings.any(errorMessage.contains)) {
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

  Future<DateTime?> getDateTimeFromBlockIndex(int spentBlockIndex) async {
    try {
      final blockRecordByHeight = await fullNode.getBlockRecordByHeight(spentBlockIndex);
      return blockRecordByHeight.blockRecord?.dateTime;
    } catch (e) {
      return null;
    }
  }

  Future<int?> getCurrentBlockIndex() async {
    final blockchainState = await getBlockchainState();
    return blockchainState?.peak?.height;
  }

  Future<DateTime?> getCurrentBlockDateTime() async {
    final currentHeight = await getCurrentBlockIndex();

    if (currentHeight == null) return null;

    final currentDateTime = getDateTimeFromBlockIndex(currentHeight);

    return currentDateTime;
  }

  Future<Coin?> getSingleChildCoinFromCoin(Coin messageCoin) async {
    try {
      final messageCoinSpend = await getCoinSpend(messageCoin);
      final messageCoinChildId = (await messageCoinSpend!.additionsAsync).single.id;
      final messageCoinChild = await getCoinById(messageCoinChildId);
      return messageCoinChild;
    } catch (e) {
      return null;
    }
  }
}

extension PushAndWaitForSpendBundle on ChiaFullNodeInterface {
  Future<void> pushAndWaitForSpendBundle(SpendBundle spendBundle, {LoggingFunction? log}) async {
    final blockChainUtils = BlockchainUtils(this, logger: log);
    await pushTransaction(spendBundle);
    await blockChainUtils.waitForSpendBundle(spendBundle);
  }
}
