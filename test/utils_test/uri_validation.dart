import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final namesdaoUri = Uri.parse(
      'https://storage1.xchstorage.cyou/namesdao/__nathan-4977960.jpg');

  final nftStorageUri = Uri.parse(
    'https://bafkreidazmyjo7hkges45moaxx3n3tjpw6se7nzifimpif65r73pmttrk4.ipfs.nftstorage.link/',
  );

  test('should validate uris', () {
    expect(
      [namesdaoUri, nftStorageUri]
          .validate({'pfs.nftstorage.link', 'storage1.xchstorage.cyou'}),
      true,
    );
  });
}
