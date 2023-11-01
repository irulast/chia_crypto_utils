@Skip('Interacts with Namesdao API')
import 'package:chia_crypto_utils/src/api/namesdao/namesdao_api.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final namesdaoInterface = NamesdaoApi();

  test('should fail getting name info for invalid name', () async {
    const name = '_namesdao.xchh';
    final nameInfo = await namesdaoInterface.getNameInfo(name);
    expect(nameInfo?.address.address, equals(null));
  });

  test('should get name info for valid name ___CloakedRegistration.xch',
      () async {
    const name = '___CloakedRegistration.xch';
    final nameInfo = await namesdaoInterface.getNameInfo(name);
    expect(
      nameInfo?.address.address,
      equals('xch1l9hj8emh7xdk3y2d4kszeuu0z6gn27s9rlc0yz7uqgyjjtd0fegsvgsjtv'),
    );
  });

  test('should get registration info', () async {
    expect(namesdaoInterface.getRegistrationInfo, returnsNormally);
  });
}
