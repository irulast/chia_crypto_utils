import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class FullNode {
  const FullNode(this.baseURL);

  final String baseURL;

  Future<CoinRecordsResponse> getCoinRecordsByPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  });

  Future<ChiaBaseResponse> pushTransaction(SpendBundle spendBundle);

  Future<CoinRecordResponse> getCoinByName(Bytes coinId);

  Future<CoinRecordsResponse> getCoinsByHint(Bytes hint);

  Future<CoinRecordsResponse> getCoinsByParentIds(
    List<Bytes> parentIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  });

  Future<CoinRecordsResponse> getCoinsByNames(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  });

  Future<CoinSpendResponse> getPuzzleAndSolution(Bytes coinId, int height);

  Future<BlockchainStateResponse> getBlockchainState();

  Future<GetAdditionsAndRemovalsResponse> getAdditionsAndRemovals(Bytes headerHash);

  Future<GetBlockRecordByHeightResponse> getBlockRecordByHeight(int height);
  Future<GetBlockRecordsResponse> getBlockRecords(int start,int end);
}
