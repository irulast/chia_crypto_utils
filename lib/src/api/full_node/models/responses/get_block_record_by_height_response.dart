import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class GetBlockRecordByHeightResponse extends ChiaBaseResponse {
  final BlockRecord? blockRecord;

  const GetBlockRecordByHeightResponse({
    this.blockRecord,
    required bool success,
    required String? error,
  }) : super(
          success: success,
          error: error,
        );

  factory GetBlockRecordByHeightResponse.fromJson(Map<String, dynamic> json) {
    final chiaBaseResponse = ChiaBaseResponse.fromJson(json);

    return GetBlockRecordByHeightResponse(
      blockRecord: BlockRecord.fromJson(json['block_record'] as Map<String, dynamic>),
      success: chiaBaseResponse.success,
      error: chiaBaseResponse.error,
    );
  }
}
