import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/core/models/blockchain_state.dart';

class BlockchainStateResponse extends ChiaBaseResponse {
  BlockchainState? blockchainState;

  BlockchainStateResponse({
    required this.blockchainState,
    required bool success,
    required String? error,
  }) : super(
    success: success,
    error: error,
  );

  factory BlockchainStateResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return BlockchainStateResponse(
      blockchainState: 
        json['blockchain_state'] != null ?
            BlockchainState.fromJson(json['blockchain_state'] as Map<String, dynamic>)
          :
            null
          ,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}
