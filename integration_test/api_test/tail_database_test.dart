@Skip('Interacts with tail database api')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final tailDatabaseApi = TailDatabaseApi();
  LoggingContext().setLogLevel(LogLevel.low);
  LoggingContext().setLogTypes(api: true);

  test('should get tail info for asset ids', () async {
    final stablyUsdAssetId =
        Puzzlehash.fromHex('6d95dae356e32a71db5ddcb42224754a02524c615c5fc35f568c2af04774e589');
    final stablyUsdTailInfo = await tailDatabaseApi.getTailInfo(stablyUsdAssetId);
    expect(stablyUsdTailInfo.name, 'Stably USD');

    final catkchiAssetId =
        Puzzlehash.fromHex('482b49902d310c53065c3531d398d41808f1390590d566815d67040f6a32d124');
    final catkchiTailInfo = await tailDatabaseApi.getTailInfo(catkchiAssetId);
    expect(catkchiTailInfo.name, 'Catkchi');

   // Chess is no longer listed on tail database after the CAT2 release.
    final chessAssetId =
        Puzzlehash.fromHex('a26bb00329235a4b46d0e402f9c1124279dcb1a30c3236679e1a7f1709a8d7c0');
    final chessTailInfo = await tailDatabaseApi.getTailInfo(chessAssetId);
    expect(chessTailInfo.name, isNull);
  });
}
