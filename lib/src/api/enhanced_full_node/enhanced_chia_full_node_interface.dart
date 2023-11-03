import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class EnhancedChiaFullNodeInterface extends ChiaFullNodeInterface {
  const EnhancedChiaFullNodeInterface(EnhancedFullNode super.fullNode);

  factory EnhancedChiaFullNodeInterface.fromUrl(
    String url, {
    Bytes? cert,
    Bytes? key,
    HeadersGetter? baseHeadersGetter,
    Duration timeout = const Duration(seconds: 15),
  }) =>
      EnhancedChiaFullNodeInterface(
        EnhancedFullNodeHttpRpc(
          url,
          certBytes: cert,
          keyBytes: key,
          timeout: timeout,
          baseHeadersGetter: baseHeadersGetter,
        ),
      );

  EnhancedFullNode get enhancedFullNode => fullNode as EnhancedFullNode;

  Future<PaginatedCoins> getCoinsByPuzzleHashesPaginated(
    List<Puzzlehash> puzzlehashes,
    int maxNumberOfCoins, {
    int? startHeight,
    int? endHeight,
    Bytes? lastId,
    bool includeSpentCoins = false,
  }) async {
    final recordsResponse =
        await enhancedFullNode.getCoinRecordsByPuzzleHashesPaginated(
      puzzlehashes,
      maxNumberOfCoins,
      startHeight: startHeight,
      endHeight: endHeight,
      lastId: lastId,
      includeSpentCoins: includeSpentCoins,
    );
    try {
      ChiaFullNodeInterface.mapResponseToError(recordsResponse);
    } catch (e) {
      final body = <String, dynamic>{
        'puzzle_hashes': puzzlehashes.map((ph) => ph.toHex()).toList(),
      };
      if (startHeight != null) {
        body['start_height'] = startHeight;
      }
      if (endHeight != null) {
        body['end_height'] = endHeight;
      }
      if (lastId != null) {
        body['last_id'] = lastId.toHex();
      }
      body['include_spent_coins'] = includeSpentCoins;
      body['page_size'] = maxNumberOfCoins;

      LoggingContext().error(
        'Error fetching paginated coins by puzzle hashes $e with request: ${jsonEncode(body)}',
      );

      rethrow;
    }
    final unspentCoins = <CoinWithParentSpend>[];
    final spentCoins = <SpentCoin>[];

    for (final coinRecord in recordsResponse.coinRecords) {
      if (coinRecord.spentBlockIndex > 0) {
        final spentCoin = coinRecord.toSpentCoin();
        spentCoins.add(spentCoin);
      } else {
        final unspentCoin = coinRecord.toCoinWithParentSpend();
        unspentCoins.add(unspentCoin);
      }
    }

    return PaginatedCoins(
      spentCoins,
      unspentCoins,
      recordsResponse.lastId,
      recordsResponse.totalCoinCount,
    );
  }

  @override
  Future<List<Coin>> getCoinsByHints(
    List<Puzzlehash> hints, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final recordsResponse = await enhancedFullNode.getCoinsByHints(
      hints,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
    ChiaFullNodeInterface.mapResponseToError(recordsResponse);
    return recordsResponse.coinRecords.map((e) => e.toCoin()).toList();
  }

  Future<PaginatedCoins> getCoinsByHintsPaginated(
    List<Puzzlehash> hints,
    int maxNumberOfCoins, {
    int? startHeight,
    int? endHeight,
    Bytes? lastId,
    bool includeSpentCoins = false,
  }) async {
    final recordsResponse =
        await enhancedFullNode.getCoinRecordsByHintsPaginated(
      hints,
      maxNumberOfCoins,
      startHeight: startHeight,
      endHeight: endHeight,
      lastId: lastId,
      includeSpentCoins: includeSpentCoins,
    );
    ChiaFullNodeInterface.mapResponseToError(recordsResponse);
    final unspentCoins = <CoinWithParentSpend>[];
    final spentCoins = <SpentCoin>[];

    for (final coinRecord in recordsResponse.coinRecords) {
      if (coinRecord.spentBlockIndex > 0) {
        final spentCoin = coinRecord.toSpentCoin();
        spentCoins.add(spentCoin);
      } else {
        final unspentCoin = coinRecord.toCoinWithParentSpend();
        unspentCoins.add(unspentCoin);
      }
    }

    return PaginatedCoins(
      spentCoins,
      unspentCoins,
      recordsResponse.lastId,
      recordsResponse.totalCoinCount,
    );
  }

  Future<List<NftRecord>> getNftRecordsByHints(
    List<Puzzlehash> hints, {
    int? startHeight,
    int? endHeight,
  }) async {
    final coins = await getCoinsByHints(
      hints,
      startHeight: startHeight,
      endHeight: endHeight,
    );

    return getNftRecordsFromCoins(coins);
  }

  @override
  Future<List<NftRecord>> getNftRecordsFromCoins(List<Coin> coins) async {
    final nfts = <NftRecord>[];

    final parentSpends = await getCoinSpendsByIds(
      coins.map((e) => e.parentCoinInfo).toList(),
    );

    for (final coin in coins) {
      if (coin.amount != 1) {
        continue;
      }
      final parentSpend = parentSpends[coin.parentCoinInfo];
      final nftRecord = await NftRecord.fromParentCoinSpendAsync(
        parentSpend!,
        coin,
        latestHeight: coin.confirmedBlockIndex,
      );
      if (nftRecord != null) {
        nfts.add(nftRecord);
      }
    }

    return nfts;
  }

  Future<List<CatFullCoin>> getCatCoinsByHints(
    List<Puzzlehash> hints, {
    int? startHeight,
    int? endHeight,
  }) async {
    final coins = await getCoinsByHints(
      hints,
      startHeight: startHeight,
      endHeight: endHeight,
    );

    return hydrateCatCoins(coins);
  }

  @override
  Future<Map<Bytes, CoinSpend>> getCoinSpendsByIds(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
  }) async {
    final response = await enhancedFullNode.getPuzzlesAndSolutionsByNames(
      coinIds,
      startHeight: startHeight,
      endHeight: endHeight,
    );
    ChiaFullNodeInterface.mapResponseToError(response);

    return response.coinSpendsMap;
  }

  Future<AdditionsAndRemovalsWithHints> getAdditionsAndRemovalsWithHints(
    Bytes headerHash,
  ) async {
    final response =
        await enhancedFullNode.getAdditionsAndRemovalsWithHints(headerHash);
    ChiaFullNodeInterface.mapResponseToError(response);
    return AdditionsAndRemovalsWithHints(
      additions: response.additions!,
      removals: response.removals!,
    );
  }

  Future<List<DidRecord>> getDidRecordsByHints(List<Puzzlehash> hints) async {
    final coins = await getCoinsByHints(hints);
    return getDidsFromCoins(coins);
  }

  @override
  Future<DidRecord?> getDidRecordFromHint(Puzzlehash hint, Bytes did) async {
    final coins = await getCoinsByHints([hint]);
    final didInfos = await getDidsFromCoins(coins);
    final matches = didInfos.where((element) => element.did == did);

    if (matches.isEmpty) return null;
    return matches.single;
  }

  @override
  Future<List<DidRecord>> getDidsFromCoins(List<Coin> coins) async {
    final didInfos = <DidRecord>[];
    final parentSpends =
        await getCoinSpendsByIds(coins.map((e) => e.parentCoinInfo).toList());
    for (final coin in coins) {
      if (coin.amount.isEven) {
        continue;
      }
      final parentSpend = parentSpends[coin.parentCoinInfo];
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
}
