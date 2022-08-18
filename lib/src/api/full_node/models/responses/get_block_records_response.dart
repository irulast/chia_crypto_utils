import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class GetBlockRecordsResponse extends ChiaBaseResponse {
  final List<BlockRecord>? blockRecords;

  const GetBlockRecordsResponse({
    this.blockRecords,
    required bool success,
    required String? error,
  }) : super(
          success: success,
          error: error,
        );

  factory GetBlockRecordsResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    final blockRecords = (json['block_records'] != null)
        ? List<Map<String, dynamic>>.from(json['block_records'] as Iterable)
            .map(BlockRecord.fromJson)
            .toList()
        : null;

    return GetBlockRecordsResponse(
      blockRecords: blockRecords,
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}
