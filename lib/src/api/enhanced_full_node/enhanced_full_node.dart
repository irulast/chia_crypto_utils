import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/enhanced_full_node/models/responses/coin_spends_by_ids_response.dart';

abstract class EnhancedFullNode extends FullNode {
  EnhancedFullNode(super.baseURL);

  Future<CoinRecordsWithCoinSpendsResponse>
      getCoinRecordsByPuzzleHashesPaginated(
    List<Puzzlehash> puzzlehashes,
    int maxNumberOfCoins, {
    int? startHeight,
    int? endHeight,
    Bytes? lastId,
    bool includeSpentCoins = false,
  });

  Future<CoinRecordsResponse> getCoinsByHints(
    List<Puzzlehash> hints, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  });

  Future<CoinRecordsWithCoinSpendsResponse> getCoinRecordsByHintsPaginated(
    List<Puzzlehash> hints,
    int maxNumberOfCoins, {
    int? startHeight,
    int? endHeight,
    Bytes? lastId,
    bool includeSpentCoins = false,
  });

  Future<GetAdditionsAndRemovalsWithHintsResponse>
      getAdditionsAndRemovalsWithHints(
    Bytes headerHash,
  );

  Future<GetCoinSpendsByIdsResponse> getPuzzlesAndSolutionsByNames(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
  });
}
