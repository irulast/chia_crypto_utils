import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  final expectedMetadataHash = Bytes.fromHex(
      '2a547a139a5f8d56268525cdec4ffd5117f81d904475c5bcb60e3c58a6121fa7');
  final expectedDataHash = Bytes.fromHex(
      '0974e28983f967f94025b0b37e27e785e0d05b8f59d9b9686127924095ad0c87');

  final uriHashProvider = UriHashProvider();

  test('should get correct hashes for uris', () async {
    final metadataHash = await uriHashProvider.getHashForUri(
      'https://bafkreibkkr5bhgs7rvlcnbjfzxwe77krc74b3eceoxc3znqohrmkmeq7u4.ipfs.nftstorage.link',
    );
    expect(metadataHash, expectedMetadataHash);

    final dataHash = await uriHashProvider.getHashForUri(
      'https://bafybeig2qppvy5fshqssy7mg2566clpopapplgvzfby4h66dn6r3fop55i.ipfs.nftstorage.link',
    );

    expect(dataHash, expectedDataHash);
  });
}
