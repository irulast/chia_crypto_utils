import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/enhanced_full_node/models/responses/coin_spends_by_ids_response.dart';

// enhanced endpoint decorator to FullNode
class EnhancedFullNodeHttpRpc implements EnhancedFullNode {
  const EnhancedFullNodeHttpRpc(
    this.baseURL, {
    this.certBytes,
    this.keyBytes,
    this.baseHeadersGetter,
    this.timeout = const Duration(seconds: 15),
  });

  @override
  final String baseURL;
  final Bytes? certBytes;
  final Bytes? keyBytes;

  final Duration timeout;
  final HeadersGetter? baseHeadersGetter;

  FullNodeHttpRpc get _delegate => FullNodeHttpRpc(
        baseURL,
        certBytes: certBytes,
        keyBytes: keyBytes,
        timeout: timeout,
        baseHeadersGetter: baseHeadersGetter,
      );

  Client get client => _delegate.client;

  @override
  Future<CoinRecordsWithCoinSpendsResponse> getCoinRecordsByPuzzleHashesPaginated(
    List<Puzzlehash> puzzlehashes,
    int maxNumberOfCoins, {
    int? startHeight,
    int? endHeight,
    Bytes? lastId,
    bool includeSpentCoins = false,
  }) async {
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

    final response = await client.post(
      Uri.parse('get_coin_records_by_puzzle_hashes_paginated'),
      body,
    );
    FullNodeHttpRpc.mapResponseToError(response);

    return CoinRecordsWithCoinSpendsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<CoinRecordsResponse> getCoinsByHints(
    List<Puzzlehash> hints, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final body = <String, dynamic>{
      'hints': hints.map((e) => e.toHex()).toList(),
    };

    if (startHeight != null) {
      body['start_height'] = startHeight;
    }
    if (endHeight != null) {
      body['end_height'] = endHeight;
    }
    body['include_spent_coins'] = includeSpentCoins;
    final response = await client.post(
      Uri.parse('get_coin_records_by_hints'),
      body,
    );
    FullNodeHttpRpc.mapResponseToError(response);

    return CoinRecordsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<CoinRecordsWithCoinSpendsResponse> getCoinRecordsByHintsPaginated(
    List<Puzzlehash> hints,
    int maxNumberOfCoins, {
    int? startHeight,
    int? endHeight,
    Bytes? lastId,
    bool includeSpentCoins = false,
  }) async {
    final body = <String, dynamic>{
      'hints': hints.map((hint) => hint.toHex()).toList(),
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

    final response = await client.post(
      Uri.parse('get_coin_records_by_hints_paginated'),
      body,
    );
    FullNodeHttpRpc.mapResponseToError(response);

    return CoinRecordsWithCoinSpendsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<GetAdditionsAndRemovalsWithHintsResponse> getAdditionsAndRemovalsWithHints(
    Bytes headerHash,
  ) async {
    final response = await client.post(
      Uri.parse('get_additions_and_removals_with_hints'),
      <String, dynamic>{'header_hash': headerHash.toHex()},
    );
    FullNodeHttpRpc.mapResponseToError(response);

    return GetAdditionsAndRemovalsWithHintsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<GetAdditionsAndRemovalsResponse> getAdditionsAndRemovals(Bytes headerHash) {
    return _delegate.getAdditionsAndRemovals(headerHash);
  }

  @override
  Future<MempoolItemsResponse> getAllMempoolItems() {
    return _delegate.getAllMempoolItems();
  }

  @override
  Future<GetBlockRecordByHeightResponse> getBlockRecordByHeight(int height) {
    return _delegate.getBlockRecordByHeight(height);
  }

  @override
  Future<GetBlockRecordsResponse> getBlockRecords(int start, int end) {
    return _delegate.getBlockRecords(start, end);
  }

  @override
  Future<BlockchainStateResponse> getBlockchainState() {
    return _delegate.getBlockchainState();
  }

  @override
  Future<CoinRecordResponse> getCoinByName(Bytes coinId) {
    return _delegate.getCoinByName(coinId);
  }

  @override
  Future<CoinRecordsResponse> getCoinRecordsByPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) {
    return _delegate.getCoinRecordsByPuzzleHashes(
      puzzlehashes,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
  }

  @override
  Future<CoinRecordsResponse> getCoinsByHint(
    Puzzlehash hint, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) {
    return getCoinsByHints(
      [hint],
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
  }

  @override
  Future<GetCoinSpendsByIdsResponse> getPuzzlesAndSolutionsByNames(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
  }) async {
    final body = <String, dynamic>{
      'names': coinIds.map((coinId) => coinId.toHex()).toList(),
    };
    if (startHeight != null) {
      body['start_height'] = startHeight;
    }
    if (endHeight != null) {
      body['end_height'] = endHeight;
    }
    final response = await client.post(Uri.parse('get_puzzles_and_solutions_by_names'), body);
    FullNodeHttpRpc.mapResponseToError(response);

    return GetCoinSpendsByIdsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<CoinRecordsResponse> getCoinsByNames(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) {
    return _delegate.getCoinsByNames(
      coinIds,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
  }

  @override
  Future<CoinRecordsResponse> getCoinsByParentIds(
    List<Bytes> parentIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) {
    return _delegate.getCoinsByParentIds(
      parentIds,
      startHeight: startHeight,
      endHeight: endHeight,
      includeSpentCoins: includeSpentCoins,
    );
  }

  @override
  Future<CoinSpendResponse> getPuzzleAndSolution(Bytes coinId, int height) {
    return _delegate.getPuzzleAndSolution(coinId, height);
  }

  @override
  Future<ChiaBaseResponse> pushTransaction(SpendBundle spendBundle) {
    return _delegate.pushTransaction(spendBundle);
  }

  @override
  Future<GetBlockResponse> getBlock(Bytes headerHash) {
    return _delegate.getBlock(headerHash);
  }

  @override
  Future<GetBlocksResponse> getBlocks(
    int start,
    int end, {
    bool excludeHeaderHash = false,
    bool excludeReorged = false,
  }) {
    return _delegate.getBlocks(
      start,
      end,
      excludeHeaderHash: excludeHeaderHash,
      excludeReorged: excludeReorged,
    );
  }
}
