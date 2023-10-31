import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/full_block.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class GetBlockResponse extends ChiaBaseResponse {
  const GetBlockResponse({
    required this.block,
    required super.success,
    required super.error,
  });

  factory GetBlockResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    final block = pick(json, 'block').letJsonOrNull(FullBlock.fromJson);

    return GetBlockResponse(
      block: block,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
  final FullBlock? block;
}
