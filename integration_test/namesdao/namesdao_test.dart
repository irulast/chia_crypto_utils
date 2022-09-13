import 'package:chia_crypto_utils/src/api/namesdao/namesdao_api.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const name1 = '_namesdao.xchh';
  const name2 = '___CloakedRegistration.xch';

  final namesdaoInterface = NamesdaoApi();
  test('should get name info for name', () async {
    final name1Info = await namesdaoInterface.getNameInfo(name1);
    expect(name1Info?.address.address, equals(null));

    final name2Info = await namesdaoInterface.getNameInfo(name2);
    expect(name2Info?.address.address, equals('xch1l9hj8emh7xdk3y2d4kszeuu0z6gn27s9rlc0yz7uqgyjjtd0fegsvgsjtv'));
  });
}
