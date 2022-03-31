import 'package:chia_utils/src/api/models/responses/blockchain_state_response.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_record_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_records_response.dart';
import 'package:chia_utils/src/api/models/responses/coin_spend_response.dart';
import 'package:chia_utils/src/core/models/index.dart';

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

  Future<CoinRecordResponse> getCoinByName(Puzzlehash coinId);

  Future<CoinSpendResponse> getPuzzleAndSolution(Puzzlehash coinId, int height);

  Future<BlockchainStateResponse> getBlockchainState();
}
