import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/tail_database/tail_database_api.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final holidayAssetId = Puzzlehash.fromHex(
    '509deafe3cd8bbfbb9ccce1d930e3d7b57b40c964fa33379b18d628175eb7a8f',
  );
  final chessAssetId = Puzzlehash.fromHex(
    'a26bb00329235a4b46d0e402f9c1124279dcb1a30c3236679e1a7f1709a8d7c0',
  );
  final tailDatabaseInterface = TailDatabaseApi();
  test('should get tail info for asset ids', () async {
    final holidayTailInfo = await tailDatabaseInterface.getTailInfo(holidayAssetId);
    expect(holidayTailInfo.name, equals('Chia Holiday 2021'));

    final chessTailInfo = await tailDatabaseInterface.getTailInfo(chessAssetId);
    expect(chessTailInfo.name, equals('Chess'));
  });
}
