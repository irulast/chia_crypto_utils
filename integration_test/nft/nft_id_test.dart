import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should get correct mint garden link for nft', () async {
    final launcherId =
        Bytes.fromHex('dcb1e09d7a3053b31cd512a161d5d8f54deaac4d7d16d0119dfd597b122d3269');
    const actualLink =
        'https://mintgarden.io/nfts/nft1mjc7p8t6xpfmx8x4z2skr4wc74x74tzd05tdqyval4vhky3dxf5su3q2em';
    final nftId = NftId.fromLauncherId(launcherId);
    expect(nftId.mintGardenLink, actualLink);
  });
}
