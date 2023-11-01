import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/full_block.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class GetBlocksResponse extends ChiaBaseResponse {
  const GetBlocksResponse({
    required this.blocks,
    required super.success,
    required super.error,
  });

  factory GetBlocksResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    final blocks = pick(json, 'blocks').letJsonListOrNull(FullBlock.fromJson);

    return GetBlocksResponse(
      blocks: blocks ?? [],
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
  final List<FullBlock> blocks;
}
