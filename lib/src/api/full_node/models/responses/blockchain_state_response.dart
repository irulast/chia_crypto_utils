// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/api/full_node/models/responses/chia_base_response.dart';
import 'package:chia_crypto_utils/src/core/models/blockchain_state.dart';
import 'package:meta/meta.dart';

@immutable
class BlockchainStateResponse extends ChiaBaseResponse {
  final BlockchainState? blockchainState;

  const BlockchainStateResponse({
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
      blockchainState: json['blockchain_state'] != null
          ? BlockchainState.fromJson(
              json['blockchain_state'] as Map<String, dynamic>,
            )
          : null,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}
