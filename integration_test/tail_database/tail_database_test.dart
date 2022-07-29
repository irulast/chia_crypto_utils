import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/tail_database/tail_database_api.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final holidayAssetId = Puzzlehash.fromHex(
    '509deafe3cd8bbfbb9ccce1d930e3d7b57b40c964fa33379b18d628175eb7a8f',
  );
  final caesarCoinAssetId = Puzzlehash.fromHex(
    '125ef688c3200d4a82248c31f6dcfe2dc45d549b779c0b3b1ef35568fea840b6',
  );

  final tailDatabaseInterface = TailDatabaseApi();
  test('should get tail info for asset ids', () async {
    final holidayTailInfo = await tailDatabaseInterface.getTailInfo(holidayAssetId);
    expect(holidayTailInfo.name, equals('Chia Holiday 2021'));

    final chessTailInfo = await tailDatabaseInterface.getTailInfo(caesarCoinAssetId);
    expect(chessTailInfo.name, equals('A Golden Caesar'));
  });
}
