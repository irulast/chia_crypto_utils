import 'package:chia_crypto_utils/src/api/namesdao/namesdao_api.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const name1 = '_namesdao.xchh';
  const name2 = '_Namesdao.xch';

  final namesdaoInterface = NamesdaoApi();
  test('should get name info for name', () async {
    final name1Info = await namesdaoInterface.getNameInfo(name1);
    expect(name1Info?.address.address, equals(null));

    final name2Info = await namesdaoInterface.getNameInfo(name2);
    expect(name2Info?.address.address, equals('xch1jhye8dmkhree0zr8t09rlzm9cc82mhuqtp5tlmsj4kuqvs69s2wsl90su4'));
  });
}
